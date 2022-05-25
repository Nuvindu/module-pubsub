import ballerina/io;
import nuvindu/pubsub;
import ballerina/lang.runtime;

public function main() returns error? {
    pubsub:PubSub pubsub = new();
    map<stream<any,error?>> receivers = {};
    string[] names = ["Mike", "Kim", "Jimmy"];

    foreach string name in names {
        receivers[name] = check pubsub.subscribe("topic");        
    }
    
    string[] news = check getNews();
    
    worker A {
        foreach string data in news {
            error? publish = pubsub.publish("topic", data);
            if publish is error {
                io:println(publish);
            }
            runtime:sleep(5);
        }
        error? gracefulShutdown = pubsub.gracefulShutdown();
        if gracefulShutdown !is error {
            io:println("Pub/Sub is closed.");
        }
    }

    @strand {
        thread: "any" 
    }
    worker B {
        foreach int i in 0..<3 {
            foreach string key in receivers.keys() {
                if i == 1 && key == "Mike" {
                    error? close = receivers.get(key).close();
                    io:print(close);
                }
                record {| any value; |}|error? next = receivers.get(key).next();
                if next !is error? {
                    io:println(key,": ", next.value);
                }
            }
            io:println("..............................");
        }
    }
}
