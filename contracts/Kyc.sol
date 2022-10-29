pragma solidity >=0.4.22 <0.9.0;

contract KYC {
    address admin;

    constructor() public {
        admin = msg.sender;
    }

    struct Customer {
        string userName;
        string data;
        uint256 upVotes;
        uint256 downVotes;
        address bankAddress;
        bool kycStatus;
    }

    struct Bank {
        string name;
        address ethAddress;
        uint256 registrationNumber;
        uint256 kyc_count;
        bool kycPermission;
        uint256 report;
    }

    struct KYC_request {
        string userName;
        address bankAddress;
        string customerData;
    }

    mapping(string => Customer) public customerList;
    mapping(address => Bank) public bankList;
    address[] bankAddresses;
    mapping(string => KYC_request) public requestList;

    function isAdmin(address senderAddress) private view returns (bool) {
        if (admin == senderAddress) {
            return true;
        } else {
            return false;
        }
    }

    function isBanKExists(address ethAddress) private view returns (bool) {
        if (bankList[ethAddress].ethAddress == ethAddress) {
            return true;
        }
        return false;
    }

    function isCustomerExists(string memory customerName)
        private
        view
        returns (bool)
    {
        if (
            (keccak256(bytes(customerList[customerName].userName)) ==
                keccak256(bytes(customerName)))
        ) {
            return true;
        }
        return false;
    }

    function isKYCRequestExists(string memory customerName)
        private
        view
        returns (bool)
    {
        if (
            keccak256(bytes(requestList[customerName].userName)) ==
            keccak256(bytes(customerName))
        ) {
            return true;
        }
        return false;
    }

    function getTotalBanks() private view returns (uint256) {
        return bankAddresses.length;
    }

    function getBankPermissionStatus(address bankAddress)
        public
        view
        returns (bool)
    {
        return bankList[bankAddress].kycPermission;
    }

    // Access modifiers
    modifier checkIfUserExists(string memory customerName) {
        require(isBanKExists(msg.sender), "Not authorised");
        require(!isCustomerExists(customerName), "Customer already exists");
        _;
    }

    modifier checkIfBankExists(address bankAddress) {
        require(!isBanKExists(bankAddress), "Bank already exists");
        _;
    }

    modifier checkIfRequestAlreadyExists(string memory customerName) {
        require(
            !isKYCRequestExists(customerName),
            "Customer Request already exists"
        );
        _;
    }

    modifier checkIfIsAdmin(address userAddress) {
        require(isAdmin(userAddress), "Not Authorised");
        _;
    }

    modifier authorisedBank(address bankAddress) {
        require(getBankPermissionStatus(bankAddress), "Bank is not Authorised");
        _;
    }

    function addCustomer(string memory userName, string memory hashData)
        public
        checkIfUserExists(hashData)
        returns (uint256)
    {
        //require(bankList[msg.sender], "Invalid Bank address");
        customerList[userName] = Customer(
            userName,
            hashData,
            0,
            0,
            msg.sender,
            false
        );
        return 1;
    }

    function removeCustomer(string memory customerName) public returns (bool) {
        delete requestList[customerName];
        delete customerList[customerName];
        return true;
    }

    function modifyCustomer(
        string memory customerName,
        string memory customerData
    ) public returns (bool) {
        require(isCustomerExists(customerName), "Customer doesnot exists");
        if (isKYCRequestExists(customerName)) {
            delete requestList[customerName];
        }
        customerList[customerName].data = customerData;
        customerList[customerName].upVotes = 0;
        customerList[customerName].downVotes = 0;
        customerList[customerName].kycStatus = false;
        return true;
    }

    function getCustomerDetails(string memory customerName)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            address,
            bool
        )
    {
        require(isCustomerExists(customerName), "Customer doesnot exists");
        Customer memory details = customerList[customerName];
        return (
            details.userName,
            details.data,
            details.upVotes,
            details.downVotes,
            details.bankAddress,
            details.kycStatus
        );
    }

    //Bank Interface
    function addBank(
        string memory bankName,
        address bankAddress,
        uint256 registrationNumber
    )
        public
        checkIfBankExists(bankAddress)
        checkIfIsAdmin(msg.sender)
        returns (uint256)
    {
        bankList[bankAddress] = Bank(
            bankName,
            bankAddress,
            registrationNumber,
            0,
            true,
            0
        );
        bankAddresses.push(bankAddress);
        return 1;
    }

    // To report Bank
    function reportBank(address bankAddress) public returns (bool) {
        require(isBanKExists(msg.sender), "Not authorised");
        require(isBanKExists(bankAddress), "Bank doesnot exists");
        bankList[bankAddress].report++;
        uint256 totalBanks = getTotalBanks();

        //To set kycPermission to false if reporte more by 33 percent of banks
        if ((bankList[bankAddress].report * 100) / totalBanks > 33) {
            bankList[bankAddress].kycPermission = false;
        }
        return true;
    }

    // Modify KYC status
    function modifyBankKycPermission(bool status, address bankAddress)
        public
        checkIfIsAdmin(msg.sender)
    {
        bankList[bankAddress].kycPermission = status;
    }

    //view Bank Details
    function getBankDetails(address bankAddress)
        public
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        require(isBanKExists(bankAddress), "Bank doesnot exists");
        Bank memory details = bankList[bankAddress];
        return (
            details.name,
            details.ethAddress,
            details.registrationNumber,
            details.kyc_count,
            details.kycPermission,
            details.report
        );
    }

    //remove bankAddress
    function removeBank(address bankAddress) public checkIfIsAdmin(msg.sender) {
        delete bankList[bankAddress];
    }

    //KYC Request functions
    function createRequest(
        string memory customerName,
        string memory customerData
    ) public checkIfRequestAlreadyExists(customerName) returns (uint256) {
        require(getBankPermissionStatus(msg.sender), "Bank Has been Reported");
        requestList[customerName] = KYC_request(
            customerName,
            msg.sender,
            customerData
        );
        return 1;
    }

    // To upvote
    function upvoteCustomer(string memory customerName)
        public
        authorisedBank(msg.sender)
        returns (bool)
    {
        require(
            isKYCRequestExists(customerName),
            "KYC request for the customer doesnot exists"
        );
        customerList[customerName].upVotes++;
        if (
            customerList[customerName].downVotes <
            customerList[customerName].upVotes
        ) {
            customerList[customerName].kycStatus = true;
        }
        return true;
    }

    //Down vote the customer
    function downvoteCustomer(string memory customerName)
        public
        authorisedBank(msg.sender)
        returns (bool)
    {
        require(
            isKYCRequestExists(customerName),
            "KYC request for the customer doesnot exists"
        );
        uint256 totalBanks = getTotalBanks();
        customerList[customerName].downVotes++;

        // To set kysStatus to false condition
        if (
            customerList[customerName].downVotes >
            customerList[customerName].upVotes
        ) {
            customerList[customerName].kycStatus = false;
        } else {
            if (totalBanks > 5) {
                if (
                    (customerList[customerName].downVotes * 100) / totalBanks >
                    33
                ) {
                    customerList[customerName].kycStatus = false;
                }
            }
        }

        return true;
    }

    // Get customer KYC status
    function getKycStatus(string memory customerName)
        public
        view
        returns (bool)
    {
        require(
            isKYCRequestExists(customerName),
            "KYC request for the customer doesnot exists"
        );
        return customerList[customerName].kycStatus;
    }
}
