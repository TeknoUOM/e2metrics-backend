public function savePayment(string timestamp,string id,string userId,float amountValue,string amountCurrencyCode,string subscription) returns json|error {
        json returnData = {};
        do {
            _ = check dbClient->execute(`
	            INSERT INTO Payment
                VALUES (${timestamp}, ${id},${userId},${amountValue},${amountCurrencyCode},${subscription})`);
                returnData={
                    status:200
                };
                return returnData;
        } on fail var err {
            return err;
        }
        
};