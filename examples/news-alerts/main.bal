import ballerina/io;
import nuvindu_dias/pubsub;

public function main() returns error? {
    pubsub:PubSub pubsub = new();
    map<stream<any,error?>> receivers = {};
    string[] names = ["kim", "mike", "nacho"];

    foreach string name in names {
        receivers[name] = check pubsub.subscribe("topic");        
    }
    foreach int i in 1..<4 {
        error? publish = pubsub.publish(i.toString(), "topic");
        if publish is error {
            io:println(publish);
        }
    }
    foreach int i in 0..<3 {
        foreach string key in receivers.keys() {
            record {| any value; |}|error? next = receivers.get(key).next();
            if next is error? {
                break;
            }
            io:println(key,": ", next.value);
        }   
    }
    error? gracefulShutDown = pubsub.gracefulShutdown();
    if gracefulShutDown is error {
        io:println(gracefulShutDown);
    }  
}
