import ballerina/sql;
import ballerinax/mysql;
type PaymentInDB record {
    string 'timestamp;
    string 'id;
    string 'userId;
    string 'amountValue;
    string 'amountCurrencyCode;
    string 'subscription;
};
public function savePayment(string timestamp,string id,string userId,float amountValue,string amountCurrencyCode,string subscription) returns json|error {
        json returnData = {};
        do {
        mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
            _ = check dbClient->execute(`
	            INSERT INTO Payment
                VALUES (${timestamp}, ${id},${userId},${amountValue},${amountCurrencyCode},${subscription})`);
        sql:Error? close = dbClient.close();
                returnData={
                    status:200
                };
                return returnData;
        } on fail var err {
            return err;
        }
        
};

public function getUserPayments(string userId) returns PaymentInDB[]|error {
    PaymentInDB[] responses = [];
    
    do {
        mysql:Client sqldbClient = check new (hostname, username, password, "E2Metrices", port);

        stream<PaymentInDB, sql:Error?> resultStream = sqldbClient->query(`SELECT * FROM Payment WHERE UserID = ${userId}`);
        sql:Error? close = sqldbClient.close();
        check from PaymentInDB payment in resultStream
            do {
                responses.push(payment);
            };
        check resultStream.close();
        return responses;
    } on fail error e {
        return e;
    }
        
};