import nuvindu/pipe;

# An Events Transmission Model with Publish/Subscribe APIs.
public class PubSub {
    private map<pipe:Pipe[]> topics;
    private boolean isClosed;
    private boolean autoCreateTopics;

    # Creates a new `pubsub:PubSub` instance.
    #
    # + autoCreateTopics - `Topics` are automatically created when publishing/subscribing to a non-existing topics
    public isolated function init(boolean autoCreateTopics = true) {
        self.topics = {};
        self.isClosed = false;
        self.autoCreateTopics = autoCreateTopics;
    }

    # Publishes events into a `Topic` of the PubSub. That will be broadcast to all the subscribers of that topic.
    #
    # + event - Event that needs to be published to PubSub. Can be `any` type
    # + topicName - The name of the topic which is used to publish events
    # + timeout - The maximum waiting period to hold events (Default timeout: 30 seconds)
    # + return - Returns `()` if event is successfully published. Otherwise, returns a `pubsub:Error`
    public function publish(string topicName, any event, decimal timeout = 30) returns Error? {
        if self.isClosed {
            return error Error("Events cannot be published to a closed PubSub.");
        }
        if !self.topics.hasKey(topicName) {
            if !self.autoCreateTopics {
                return error Error(topicName + " : topic does not exist.");
            }
            check self.createTopic(topicName);
        }
        pipe:Pipe[] pipes = <pipe:Pipe[]>self.topics[topicName];
        pipe:Pipe[] removedPipes = [];
        future<pipe:Error?>[] waitingQueue = [];
        foreach pipe:Pipe pipe in pipes {
            if !pipe.isClosed() {
                future<pipe:Error?> asyncValue = start self.produceData(pipe, event, timeout);
                waitingQueue.push(asyncValue);
            } else {
                removedPipes.push(pipe);
            }
        }
        foreach future<pipe:Error?> asyncValue in waitingQueue {
            pipe:Error? produce = wait asyncValue;
            if produce is pipe:Error {
                return error Error("Failed to publish events.", produce);
            }
        }
        foreach pipe:Pipe pipe in removedPipes {
            check self.unsubscribe(topicName, pipe);
        }
    }

    private function produceData(pipe:Pipe pipe, any event, decimal timeout) returns pipe:Error? {
        check pipe.produce(event, timeout);
    }

    # Subscribes to a `Topic` in the PubSub. Subscriber will receive the events published into that topic.
    #
    # + topicName - The name of the topic which is used to subscribe
    # + 'limit - The maximum number of entries that holds in the Pipe at once. Default value is five
    # + timeout - The maximum waiting period to receive events (Default timeout: 30 seconds)
    # + return - Returns `stream<any, error?>` if the user is successfully subscribed to the topic.
    # Otherwise returns a `pubsub:Error`
    public function subscribe(string topicName, int 'limit = 5, decimal timeout = 30)
        returns stream<any, error?>|Error { //TODO: make it external, new method using 'consume()'
        if self.isClosed {
            return error Error("Users cannot subscribe to a closed PubSub.");
        }
        pipe:Pipe pipe = new ('limit);
        check self.addSubscriber(topicName, pipe);
        return pipe.consumeStream(timeout);
    }

    private isolated function unsubscribe(string topicName, pipe:Pipe pipe) returns Error? {
        lock {
            pipe:Pipe[]? pipes = self.topics[topicName];
            if pipes == () {
                return error Error("topic '" + topicName + "' does not exist.");
            }
            int i = 0;
            while i < pipes.length() {
                if pipe === pipes[i] {
                    pipe:Pipe _ = pipes.remove(i);
                    break;
                }
                i += 1;
            }
        }
    }

    private isolated function addSubscriber(string topicName, pipe:Pipe pipe) returns Error? {
        lock {
            if !self.topics.hasKey(topicName) {
                if !self.autoCreateTopics {
                    return error Error("topic '" + topicName + "' does not exist.");
                }
                check self.createTopic(topicName);
            }
            pipe:Pipe[]? pipes = self.topics[topicName];
            if pipes == () {
                self.topics[topicName] = [pipe];
            } else {
                pipes.push(pipe);
            }
        }
    }

    # Creates a new `Topic` in the PubSub.
    #
    # + topic - The name of the topic which is used to publish/subscribe
    # + return - Returns `()` if the topic is successfully added to the PubSub. Otherwise returns a `pubsub:Error`
    public isolated function createTopic(string topic) returns Error? {
        lock {
            if self.topics.hasKey(topic) {
                return error Error("Topic name '" + topic + "' already exists.");
            }
            self.topics[topic] = [];
        }
    }

    # Closes the PubSub gracefully. Waits for some grace period until all the pipes in the PubSub is gracefully closed.
    #
    # + return - Returns `()`, if the PubSub is successfully shutdown. Otherwise returns a `pubsub:Error`
    public isolated function gracefulShutdown() returns Error? {
        self.isClosed = true;
        lock {
            foreach pipe:Pipe[] pipes in self.topics {
                foreach pipe:Pipe pipe in pipes {
                    error? gracefulClose = pipe.gracefulClose();
                    if gracefulClose is error {
                        return error Error("Failed to shut down the pubsub", gracefulClose);
                    }
                }
            }
            self.topics.removeAll();
        }
    }

    # Closes the PubSub instantly. All the pipes will be immediately closed.
    public isolated function forceShutdown() {
        self.isClosed = true;
        lock {
            foreach pipe:Pipe[] pipes in self.topics {
                foreach pipe:Pipe pipe in pipes {
                    pipe.immediateClose();
                }
            }
            self.topics.removeAll();
        }
    }
}
