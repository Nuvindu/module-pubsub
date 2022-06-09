// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;
import nuvindu/pipe;

# An Events Transmission Model with Publish/Subscribe APIs.
public class PubSub {
    private map<pipe:Pipe[]> topics;
    private boolean isClosed;
    private boolean autoCreateTopics;
    private pipe:Pipe pipe;

    # Creates a new `pubsub:PubSub` instance.
    #
    # + autoCreateTopics - To enable/disable auto creation of the non-existing topics when publishing/subscribing
    public isolated function init(boolean autoCreateTopics = true) {
        self.topics = {};
        self.isClosed = false;
        self.autoCreateTopics = autoCreateTopics;
        self.pipe = new (0);
    }

    # Publishes events into a `Topic` of the PubSub. That will be broadcast to all the subscribers of that topic.
    #
    # + topicName - The name of the topic which is used to publish events
    # + event - Event that needs to be published to PubSub. Can be `any` type
    # + timeout - The maximum waiting period to hold events (Default timeout: 30 seconds)
    # + return - Returns `()` if event is successfully published. Otherwise, returns a `pubsub:Error`
    public function publish(string topicName, any event, decimal timeout = 30) returns Error? {
        if self.isClosed {
            return error Error("Events cannot be published to a closed PubSub.");
        }
        if !self.topics.hasKey(topicName) {
            if !self.autoCreateTopics {
                return error Error(string `Topic "${topicName}" does not exist.`);
            }
            check self.createTopic(topicName);
        }
        pipe:Pipe[] pipes = self.topics.get(topicName);
        check self.produceAll(pipes, event, timeout, topicName);
    }

    private function produceAll(pipe:Pipe[] pipes, any event, decimal timeout, string topicName) returns Error? {
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
        check self.asyncProduce(waitingQueue);
        check self.unsubscribeClosedPipes(removedPipes, topicName);
    }

    private isolated function produceData(pipe:Pipe pipe, any event, decimal timeout) returns pipe:Error? {
        check pipe.produce(event, timeout);
    }

    private isolated function asyncProduce(future<pipe:Error?>[] waitingQueue) returns Error? {
        foreach future<pipe:Error?> asyncValue in waitingQueue {
            pipe:Error? produce = wait asyncValue;
            if produce is pipe:Error {
                return error Error("Failed to publish events.", produce);
            }
        }
    }

    private isolated function unsubscribeClosedPipes(pipe:Pipe[] removedPipes, string topicName) returns Error? {
        foreach pipe:Pipe pipe in removedPipes {
            check self.unsubscribe(topicName, pipe);
        }
    }

    # Subscribes to a `Topic` in the PubSub. Subscriber will receive the events published into that topic. 
    # Every subscriber will receive a `stream` that is attached to a separate `pipe:Pipe` instance. 
    #
    # + topicName - The name of the topic which is used to subscribe
    # + 'limit - The maximum number of entries that are held in the `pipe:Pipe` at once
    # + timeout - The maximum waiting period to receive events (Default timeout: 30 seconds)
    # + typeParam - The `type` of data that is needed to be consumed. When not provided, the type is inferred 
    # using the expected type from the function
    # + return - Returns `stream<any, error?>` if the user is successfully subscribed to the topic.
    # Otherwise returns a `pubsub:Error`
    public isolated function subscribe(string topicName, int 'limit = 5, decimal timeout = 30,
                                       typedesc<any> typeParam = <>)
        returns stream<typeParam, error?>|Error = @java:Method {
        'class: "org.nuvindu.pubsub.PubSub"
    } external;

    private isolated function unsubscribe(string topicName, pipe:Pipe pipe) returns Error? {
        lock {
            pipe:Pipe[] pipes = self.topics.get(topicName);
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

    # Creates a new `Topic` in the PubSub.
    #
    # + topicName - The name of the topic which is used to publish/subscribe
    # + return - Returns `()` if the topic is successfully added to the PubSub. Otherwise returns a `pubsub:Error`
    public isolated function createTopic(string topicName) returns Error? {
        lock {
            if self.topics.hasKey(topicName) {
                return error Error(string `Topic "${topicName}" already exists.`);
            }
            self.topics[topicName] = [];
        }
    }

    # Closes the PubSub gracefully. Waits for some grace period until all the pipes in the PubSub is gracefully closed.
    #
    # + timeout - The grace period to wait until the pipes are gracefully closed
    # + return - Returns `()`, if the PubSub is successfully shutdown. Otherwise returns a `pubsub:Error`
    public isolated function gracefulShutdown(decimal timeout = 30) returns Error? {
        self.isClosed = true;
        lock {
            foreach pipe:Pipe[] pipes in self.topics {
                foreach pipe:Pipe pipe in pipes {
                    pipe:Error? gracefulClose = pipe.gracefulClose(timeout);
                    if gracefulClose is pipe:Error {
                        return error Error("Failed to shut down the pubsub", gracefulClose);
                    }
                }
            }
            self.topics.removeAll();
        }
    }

    # Closes the PubSub instantly. All the pipes will be immediately closed.
    #
    # + return - Returns `()`, if the PubSub is successfully shutdown. Otherwise returns a `pubsub:Error`
    public isolated function forceShutdown() returns Error? {
        self.isClosed = true;
        lock {
            foreach pipe:Pipe[] pipes in self.topics {
                foreach pipe:Pipe pipe in pipes {
                    pipe:Error? immediateClose = pipe.immediateClose();
                    if immediateClose is pipe:Error {
                        return error Error("Failed to shut down the pubsub", immediateClose);
                    }
                }
            }
            self.topics.removeAll();
        }
    }
}
