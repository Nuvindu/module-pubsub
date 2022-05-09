// import ballerina/io;
import ballerina/test;
// // Before Suite Function

// @test:BeforeSuite
// function beforeSuiteFunc() {
//     io:println("I'm the before suite function!");
// }

// Test function

@test:Config {}
function testPubSub() returns error? {
    PubSub pubsub = new();
    stream<any, error?> subscribe = pubsub.subscribe("topic");
    error? publish = pubsub.publish("hello", "topic");
    if publish is error {
        return publish;
    }
    string expectedValue = "hello";
    record {| any value; |}|error? msg = subscribe.next();
    if msg !is error? {
        string actualValue = <string> msg.value;
        test:assertEquals(expectedValue, actualValue);
    }   
}

// // Negative Test function

// @test:Config {}
// function negativeTestFunction() {
//     string name = "";
//     string welcomeMsg = hello(name);
//     test:assertEquals("Hello, World!", welcomeMsg);
// }

// // After Suite Function

// @test:AfterSuite
// function afterSuiteFunc() {
//     io:println("I'm the after suite function!");
// }
