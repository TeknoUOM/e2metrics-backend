import ballerina/http;
import ballerina/io;
import ballerina/os;

listener http:Listener httpListener =new (8080);
string API_KEY = os:getEnv("API_KEY");

service / on httpListener {
    resource function get greeting() returns string {
        io:println(API_KEY);
        return "Hello,World";
    }

}

service /callApi on httpListener {

    resource function get.() returns json|error{

        http:Client github = check new ("https://api.github.com");

        map<string> headers = {
            "Accept": "application/vnd.github.v3+json",
            "Authorization": "token " + API_KEY
        };

        json data;

        do {
	       data = check github->get("/repos/TeknoUOM/balarina-rest-api/issues",headers);
        } on fail var e {
            data  =  {"message": e.toString()};
        }

        return data;
    }


    

}