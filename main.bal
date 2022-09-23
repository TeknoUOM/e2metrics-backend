import ballerina/http;

listener http:Listener httpListener =new (8080);

service / on httpListener {
    
    resource function get greeting() returns string {
        return "Hello,World";
    }

}

service /name on httpListener {

    resource function get.(string name) returns string {
        return "Hello "+name;
    }

}
