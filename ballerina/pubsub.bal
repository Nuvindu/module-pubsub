import nuvindu_dias/pipe;

public class PubSub {
    private map<pipe:Pipe[]> events;
    private boolean isClosed;

    public function init() {
        self.events = {};
        self.isClosed = false;
    }

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

    public function addSubscriber(string eventName, pipe:Pipe pipe) returns error? {
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

    public function addEvent(string eventName, string event) returns error? {
        if self.isClosed is true {
            return error("Unsubscribing is not allowed in a closed PubSub.");
        }
        if self.events.hasKey(eventName) {
            return error("Event name already exists.");
        }
        self.events[eventName] = [];
    }

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
