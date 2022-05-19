import nuvindu_dias/pipe;

public class PubSub {
    private map<pipe:Pipe[]> events;
    private boolean isClosed;

    # Iniating a new PubSub Instance.
    public function init() {
        self.events = {};
        self.isClosed = false;
    }

    # Push data into a Topic of the PubSub. That will be broadcast to all the subscribers of that topic.
    #
    # + element - Data that needs to be published to the PubSub. Can be any type.  
    # + eventName - The name of the topic which is used to publish data. 
    # + timeout - The maximum waiting period to hold data. Default timeout is 30 seconds.
    # + return - Return () if data is successfully published. Otherwise return an error.
    public function publish(any element, string eventName, decimal timeout = 30) returns error? {
        if self.isClosed is true {
            return error("Data cannot be published to a closed PubSub.");
        }
        if self.events.hasKey(eventName) is true {
            pipe:Pipe[] pipes = <pipe:Pipe[]>self.events[eventName];
            foreach pipe:Pipe pipe in pipes {
                if pipe.isClosed() is false {
                    error? produce = pipe.produce(element, timeout);
                    if produce is error {
                        return produce;
                    }
                } else {
                    error? unsubscribeResult = self.unsubscribe(eventName, pipe);
                    if unsubscribeResult is error {
                        return unsubscribeResult;
                    }
                }
            }
        }
    }

    # Subscribe to a topic in the PubSub. Subscriber will receive the data published into that topic.
    #
    # + eventName - The name of the topic which is used to subscribe.
    # + 'limit - The maximum limit of data that holds in the Pipe at once. Default value is five.
    # + timeout - The maximum waiting period to receive data. Default timeout is 30 seconds.
    # + return - Return stream<any, error?> if the user is successfully subscribed to the topic. 
	# 			 Otherwise return an error.
    public function subscribe(string eventName, int 'limit = 5, decimal timeout = 30)
    returns stream<any, error?>|error {
        if self.isClosed is true {
            return error("Users cannot subscribe to a closed PubSub.");
        }
        pipe:Pipe pipe = new('limit);
        error? subscriber = self.addSubscriber(eventName, pipe);
        if subscriber is error {
            return subscriber;
        }
        return pipe.consumeStream(timeout);
    }

    # Unsubscribe a user from a topic in the PubSub. User will no longer receive published data on that topic.
    #
    # + eventName - The name of the topic which is used to unsubscribe.
    # + pipe - The pipe instance releavant to the user
    # + return - Return () if the user is successfully unsubscribed. Otherwise return an error.
    public function unsubscribe(string eventName, pipe:Pipe pipe) returns error? {
        if self.isClosed is true {
            return error("Unsubscribing is not allowed in a closed PubSub.");
        }
        pipe:Pipe[] pipes = <pipe:Pipe[]>self.events[eventName];
        pipe:Pipe[] modifiedPipes = [];
        foreach pipe:Pipe element in pipes {
            if pipe !== element {
                modifiedPipes.push(element);
            }
        }
        self.events[eventName] = modifiedPipes;
    }

    function addSubscriber(string eventName, pipe:Pipe pipe) returns error? {
        if self.isClosed is true {
            return error("Unsubscribing is not allowed in a closed PubSub.");
        }
        pipe:Pipe[]? pipes = self.events[eventName];
        if pipes == () {
            self.events[eventName] = [pipe];
        } else {
            pipes.push(pipe);
            self.events[eventName] = pipes;
        }
    }

    # Adding a topic to the PubSub
    #
    # + eventName - The name of the topic which is used to publish/subscribe.
    # + return - Return () if the event is successfully added to the PubSub. Otherwise return an error.
    public function addEvent(string eventName) returns error? {
        if self.isClosed is true {
            return error("Unsubscribing is not allowed in a closed PubSub.");
        }
        if self.events.hasKey(eventName) {
            return error("Event name already exists.");
        }
        self.events[eventName] = [];
    }

    # Close the PubSub gracefully. Waits for some period until all the pipes in the PubSub is gracefully closed.
    # + return - Return (), if the PubSub is successfully closed. Otherwise returns an error.
    public function gracefulShutdown() returns error? {
        self.isClosed = true;
        foreach pipe:Pipe[] pipes in self.events {
            foreach pipe:Pipe pipe in pipes {
                error? gracefulClose = pipe.gracefulClose();
                if gracefulClose is error {
                    return gracefulClose;
                }
            }
        }
        self.events.removeAll();
    }

    # Close all the Pipes in the PubSub instantly using the immediate close method.
    public function forceShutdown() {
        self.isClosed = true;
        foreach pipe:Pipe[] pipes in self.events {
            foreach pipe:Pipe pipe in pipes {
                pipe.immediateClose();
            }
        }
        self.events.removeAll();
    }
}
