import nuvindu/pipe;

# Description
public class PubSub {
    private map<pipe:Pipe[]> topics;
    private boolean isClosed;
    private boolean autoCreateTopics;

    # # Creates a new `pubsub:PubSub` instance.
    #
    # + autoCreateTopics - Topics are automatically created when publishing/subscribing to a non-existing topics
    public function init(boolean autoCreateTopics = true) {
        self.topics = {};
        self.isClosed = false;
        self.autoCreateTopics = autoCreateTopics;
    }

    # Publishes data into a Topic of the PubSub. That will be broadcast to all the subscribers of that topic.
    #
    # + data - Data that needs to be published to PubSub. Can be `any` type
    # + topicName - The name of the topic which is used to publish data
    # + timeout - The maximum waiting period to hold data (Default timeout: 30 seconds)
    # + return - Returns `()` if data is successfully published. Otherwise, returns a `pubsub:Error`
    public function publish(string topicName, any data, decimal timeout = 30) returns Error? {
        if self.isClosed {
            return error Error("Data cannot be published to a closed PubSub.");
        }
        if !self.topics.hasKey(topicName) {
            if !self.autoCreateTopics {
                return error Error("Topic Name does not exist.");
            }
            check self.createTopic(topicName);
        }
        pipe:Pipe[] pipes = <pipe:Pipe[]>self.topics[topicName];
        foreach pipe:Pipe pipe in pipes {
            if !pipe.isClosed() {
                error? produce = pipe.produce(data, timeout);
                if produce is error {
                    return error Error("Failed to publish data.", produce);
                }
            } else {
                check self.unsubscribe(topicName, pipe);
            }
        }
    }

    # Subscribes to a topic in the PubSub. Subscriber will receive the data published into that topic.
    #
    # + topicName - The name of the topic which is used to subscribe
    # + 'limit - The maximum number of entries that holds in the Pipe at once. Default value is five
    # + timeout - The maximum waiting period to receive data (Default timeout: 30 seconds)
    # + return - Returns `stream<any, error?>` if the user is successfully subscribed to the topic.
	# 			 Otherwise returns a `pubsub:Error`
    public function subscribe(string topicName, int 'limit = 5, decimal timeout = 30)
        returns stream<any, error?>|Error {
        if self.isClosed {
            return error Error("Users cannot subscribe to a closed PubSub.");
        }
        pipe:Pipe pipe = new('limit);
        check self.addSubscriber(topicName, pipe);
        return pipe.consumeStream(timeout);
    }

    private function unsubscribe(string topicName, pipe:Pipe pipe) returns Error? {
        if self.isClosed {
            return error Error("Unsubscribing is not allowed in a closed PubSub.");
        }
        pipe:Pipe[] pipes = <pipe:Pipe[]>self.topics[topicName];
        int i = 0;
        while i < pipes.length() {
            if pipe === pipes[i] {
                pipe:Pipe _ = pipes.remove(i);
                break;
            }
            i += 1;
        }
    }

    private function addSubscriber(string topicName, pipe:Pipe pipe) returns Error? {
        if self.isClosed {
            return error Error("Subscribing is not allowed in a closed PubSub.");
        }
        if !self.topics.hasKey(topicName) {
            if !self.autoCreateTopics {
                return error Error("Topic Name does not exist.");
            }
            check self.createTopic(topicName);
        }
        pipe:Pipe[]? pipes = self.topics[topicName];
        if pipes == () {
            self.topics[topicName] = [pipe];
        } else {
            pipes.push(pipe);
            self.topics[topicName] = pipes;
        }
    }

    # Creates a new topic to the PubSub.
    #
    # + topic - The name of the topic which is used to publish/subscribe
    # + return - Returns `()` if the topic is successfully added to the PubSub. Otherwise returns a `pubsub:Error`
    public function createTopic(string topic) returns Error? {
        if self.isClosed {
            return error Error("Topics cannot be added to a closed PubSub.");
        }
        if self.topics.hasKey(topic) {
            return error Error("Topic name already exists.");
        }
        self.topics[topic] = [];
    }

    # Closes the PubSub gracefully. Waits for some grace period until all the pipes in the PubSub is gracefully closed.
    # 
    # + return - Returns `()`, if the PubSub is successfully shutdown. Otherwise returns a `pubsub:Error`
    public function gracefulShutdown() returns Error? {
        self.isClosed = true;
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

    # Closes the PubSub instantly. All the pipes will be immediately closed.
    # 
    # + return - Returns `()`, if the PubSub is successfully shutdown. Otherwise returns a `pubsub:Error`
    public function forceShutdown() returns Error? {
        self.isClosed = true;
        foreach pipe:Pipe[] pipes in self.topics {
            foreach pipe:Pipe pipe in pipes {
                pipe.immediateClose();
            }
        }
        self.topics.removeAll();
    }
}
