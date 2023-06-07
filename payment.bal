import ballerina/http;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        allowMethods: ["GET", "POST", "OPTIONS", "PUT"]
    }
}
service /payment on httpListener {
    resource function post savePayment(@http:Payload map<json> reqBody) returns json|error {
        string timestamp = check reqBody.timestamp;
        string id = check reqBody.id;
        string userId= check reqBody.userId;
        float amountValue =check reqBody.amount.value;
        string amountCurrencyCode= check reqBody.amount.currency_code;
        string subscription=check reqBody.subscription;
        string basis=check reqBody.basis;
        json|error returnData = {};
        do {
            _ = check dbClient->execute(`
	            INSERT INTO Payment
                VALUES (${timestamp}, ${id},${userId},${amountValue},${amountCurrencyCode},${subscription},${basis})`);
        } on fail var err {
            returnData = err;
        }
        return returnData;
    }

    
}