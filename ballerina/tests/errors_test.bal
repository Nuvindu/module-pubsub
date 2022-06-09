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

import ballerina/test;

@test:Config {
    groups: ["pubsub", "errors"]
}
function testPublishingToNonExistingTopic() returns error? {
    PubSub pubsub = new(autoCreateTopics = false);
    string expectedValue = "Topic 'events' does not exist.";
    Error? publish = pubsub.publish("events", "hello");
    test:assertTrue(publish is Error);
    test:assertEquals(expectedValue, (<Error>publish).message());
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testSubscribingToNonExistingTopic() returns error? {
    PubSub pubsub = new(autoCreateTopics = false);
    string expectedValue = "Topic 'events' does not exist.";
    stream<any, error?>|Error subscribe = pubsub.subscribe("events");
    test:assertTrue(subscribe is Error);
    test:assertEquals(expectedValue, (<Error>subscribe).message());
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testSubscribingToClosedPubSub() returns error? {
    PubSub pubsub = new(false);
    check pubsub.gracefulShutdown();
    stream<any, error?>|Error subscribe = pubsub.subscribe("topic");
    test:assertTrue(subscribe is Error);
    string expectedValue = "Users cannot subscribe to a closed PubSub.";
    test:assertEquals(expectedValue, (<Error>subscribe).message());
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testClosingStreams() returns error? {
    PubSub pubsub = new();
    stream<any, error?> newStream1 = check pubsub.subscribe("topic");
    stream<any, error?> newStream2 = check pubsub.subscribe("topic");
    check newStream2.close();
    check pubsub.publish("topic", "data");
    string expectedValue = "Events cannot be consumed after the stream is closed";
    record {|any value;|}|error? next = newStream2.next();
    test:assertTrue(next is error);
    test:assertEquals(expectedValue, (<error>next).message());
    record {|any value;|}? message = check newStream1.next();
    expectedValue = "data";
    string actualValue = <string>((<record {|any value;|}>message).value);
    test:assertEquals(expectedValue, actualValue);
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testCreatingExistingTopics() returns error? {
    PubSub pubsub = new();
    string topicName = "topic";
    check pubsub.createTopic(topicName);
    Error? topic = pubsub.createTopic(topicName);
    test:assertTrue(topic is Error);
    string expectedValue = "Topic name '" + topicName + "' already exists.";
    test:assertEquals(expectedValue, (<Error>topic).message());
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testPublishingNullValuesToTopics() returns error? {
    PubSub pubsub = new();
    stream<any, error?>|Error subscriber = pubsub.subscribe("topic");
    test:assertTrue(subscriber !is Error);
    Error? publish = pubsub.publish("topic", ());
    test:assertTrue(publish is Error);
    string expectedValue = "Failed to publish events.";
    test:assertEquals(expectedValue, (<Error>publish).message());
    string expectedCause = "Nil values cannot be produced to a pipe.";
    string actualCause = (<error>(<Error>publish).cause()).message();
    test:assertEquals(expectedCause, actualCause);
}
