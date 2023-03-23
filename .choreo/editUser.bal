import ballerina/http;
import ballerina/io;

listener http:Listener httpListener =new (8081);
http:Client asgardeoClient = check new ("https://api.asgardeo.io",httpVersion = http:HTTP_1_1);

map<string> headers2 = {
    "Authorization": "Bearer 0613ef37-f90f-3a92-ba8d-205e7b3238c6"
};

service /primitive2 on httpListener {

    resource function get userDetails() returns json|error {
        json returnData = {};
        do {
            json data = check asgardeoClient->get("/t/tekno/scim2/Me",headers2);
            io:print(data);
            returnData = {
                name: data
            };
        } on fail var e {
            io:print(e);
}
}
}