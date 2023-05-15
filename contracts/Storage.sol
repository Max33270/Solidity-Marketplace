// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0; 


contract Marketplace {
    address[] private addresses;
    string[] private companyNames;
    string[] private roles;
    uint256[] private balances;
    uint256 id;
    mapping (uint256 => Product) products;
    mapping (uint256 => Transaction) transactions;
    address private supplier;
    address private client;
    mapping(string => bool) private registeredEmails;
    mapping(address => User) users;
    mapping (address => bool) registeredAddresses;
    Transaction[] private allTransactions;


    struct User {
        string companyName;
        string email;
        string password;
        string role;
        uint256 balance;
    }

    struct Product {
        uint256 id;
        string name;
        uint256 quantity;
        uint256 price;
        uint256 date;
        string companySupplier;
    }

    struct Transaction {
        uint256 productId;
        address seller;
        address buyer;
        uint256 price;
        uint256 totalQuantity;
        uint256 date;
    }

    constructor() {
        supplier = msg.sender;
    }

    // no duplicate emails
    modifier onlyUnregisteredEmail(string memory email) {
        require(!registeredEmails[email], "This email is already registered.");
        _;
    }

    // only supplier can do something
    modifier onlySupplier() {
        require(keccak256(bytes(users[msg.sender].role)) == keccak256(bytes("supplier")), "You are not authorized to access this function.");
        _;
    }

    // only client can do something
    modifier onlyClient() {
        require(keccak256(bytes(users[msg.sender].role)) == keccak256(bytes("client")), "You are not authorized to buy products.");
        _;
    }

    // returns all Users info
    function getEveryone() public view returns (address[] memory, string[] memory, string[] memory, uint256[] memory) {
        if (addresses.length < 1) {
            revert("No companies registered yet.");
        }
        return (addresses, companyNames, roles, balances);
    }

    // Char must be alphanumeric
    function isAlphanumeric(bytes1 b) private pure returns(bool) {
        bytes1 zero = bytes1('0');
        bytes1 nine = bytes1('9');
        bytes1 upperA = bytes1('A');
        bytes1 upperZ = bytes1('Z');
        bytes1 lowerA = bytes1('a');
        bytes1 lowerZ = bytes1('z');
        bytes1 space = bytes1(' ');
        bytes1 apostrophe = bytes1("'");
        if((b >= zero && b <= nine) || // Numbers
        (b >= upperA && b <= upperZ) || // Uppercase letters
        (b >= lowerA && b <= lowerZ) ||  // Lowercase letters
        (b == space ) || // Space
        (b == apostrophe[0])) // Apostrophe
        {
            return true;
        }
        return false;
    }

    // register a new user
    function registerUser(string memory companyName, string memory email, string memory password, string memory role, uint256 balance) public onlyUnregisteredEmail(email) {
        // Check message sender inputs
        require(bytes(companyName).length > 0 && bytes(companyName).length < 15, "Company Name is required and must be less than 15 characters.");
        require(bytes(email).length > 0 && bytes(email).length <= 30, "Email is required and must be less than 50 characters.");
        bool atFound = false;
        bool dotFound = false;
        
        // Check if email contains @ and .
        for (uint256 i = 0; i < bytes(email).length; i++) {
            if (bytes(email)[i] == "@") {
                atFound = true;
            }
            if (bytes(email)[i] == ".") {
                dotFound = true;
            }
        }
        require(atFound && dotFound, "Email must contain @ and .");

        // Check if password is not empty
        require(bytes(password).length > 0, "Password is required");

        // Check if role is supplier or client
        require(keccak256(bytes(role)) == keccak256(bytes("supplier")) || keccak256(bytes(role)) == keccak256(bytes("client")), "Role must be supplier or client.");

        // Check if the address has already been registered
        require(!registeredAddresses[msg.sender], "Address has already been registered.");

        // Create new user
        User memory newUser = User(companyName, email, password, role, balance);
        users[msg.sender] = newUser;
        registeredEmails[email] = true;
        registeredAddresses[msg.sender] = true;

        // Add user to companies array
        addresses.push(msg.sender);
        companyNames.push(companyName);
        roles.push(role);
        balances.push(balance);
    }

    // login
    function loginUser(string memory email, string memory password) public view returns (string memory) {
        if (registeredEmails[email] && keccak256(bytes(users[msg.sender].password)) == keccak256(bytes(password))) {
            return string(abi.encodePacked("Connection successful, welcome company '", users[msg.sender].companyName, "' ! (", users[msg.sender].role, ")"));
        } else {
            return "Wrong email or password.";
        }
    }

    // add a new product (only supplier)
    function addProduct(string memory name, uint256 quantity, uint256 price) public onlySupplier() {
        require(bytes(name).length > 0, "Product name is required.");
        
        // Check if product name is alphanumeric
        for (uint256 i = 0; i < bytes(name).length; i++) {
            require(isAlphanumeric(bytes(name)[i]), "Product name must be alphanumeric.");
        }

        require(quantity > 0, "Quantity must be superior to 0.");
        require(price > 0, "Price must be superior to 0.");
        
        // Create new product
        id++;
        string memory companySupplier = users[msg.sender].companyName;
        uint256 date = block.timestamp;
        Product memory newProduct = Product(id, name, quantity, price, date, companySupplier);
        products[id] = newProduct;
    } 

    // update a product (only supplier can update his own products)
    function updateProduct(uint256 productId, uint256 quantity, uint256 price) public onlySupplier() {
        Product storage product = products[productId];
        require(keccak256(bytes(product.companySupplier)) == keccak256(bytes(users[msg.sender].companyName)), "You are not authorized to update this product.");

        // Check quantity and price inputs    
        require(quantity != 0 || price != 0, "Quantity or price must be superior to 0.");
        if (quantity != 0) {
            product.quantity = quantity;
        }
        if (price != 0) {
            product.price = price;
        }
    }

    // return all products in the marketplace
    function listProducts() public view returns (Product[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= id; i++) {
            if (bytes(products[i].name).length != 0) {
                count++;
            }
        }
        Product[] memory allProducts = new Product[](count);
        uint256 j = 0;
        for (uint256 i = 1; i <= id; i++) {
            if (bytes(products[i].name).length != 0) {
                allProducts[j] = products[i];
                j++;
            }
        }
        return allProducts;
    }

    // return specific product from user input
    function searchProducts(string memory product_name) public view returns (Product[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= id; i++) {
            if (bytes(products[i].name).length != 0 && (keccak256(bytes(products[i].name)) == keccak256(bytes(product_name)) || keccak256(bytes(products[i].
            companySupplier)) == keccak256(bytes(product_name)))) {
                count++;
            }
        }
        Product[] memory foundProducts = new Product[](count);
        uint256 j = 0;
        for (uint256 i = 1; i <= id; i++) {
            if (bytes(products[i].name).length != 0 && (keccak256(bytes(products[i].name)) == keccak256(bytes(product_name)) || keccak256(bytes(products[i].
            companySupplier)) == keccak256(bytes(product_name)))) {
                foundProducts[j] = products[i];
                j++;
            }
        }
        return foundProducts;
    }

    // delete a product (only supplier can delete his own products)
    function deleteProduct(uint256 productId) public {
        Product storage product = products[productId];
        require(keccak256(bytes(product.companySupplier)) == keccak256(bytes(users[msg.sender].companyName)), "You are not authorized to delete this product.");
        delete products[productId];
    }

    // buy a product (only client can buy products)
    function buyProduct(uint256 productId, uint256 totalQuantity) public onlyClient() {
        Product storage product = products[productId];
        require(product.quantity > 0, "Product is out of stock.");
        require(totalQuantity > 0, "Quantity must be superior to 0.");
        require(totalQuantity <= product.quantity, "Quantity must be inferior or equal to the available stock.");

        // Check if client has enough money to buy the product
        uint256 totalCost = product.price * totalQuantity;
        require(users[msg.sender].balance >= totalCost, "You don't have enough money to buy this product.");
       
        // add successful transaction to allTransactions array
        Transaction memory newTransaction = Transaction(productId, supplier, msg.sender, totalQuantity, totalCost, block.timestamp);
        allTransactions.push(newTransaction);

        // update product quantity and client/supplier balance
        product.quantity -= totalQuantity;
        uint256 updatedClientBalance = users[msg.sender].balance -= totalCost;
        uint256 updatedSupplierBalance = users[supplier].balance += totalCost;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (keccak256(bytes(users[addresses[i]].companyName)) == keccak256(bytes(users[msg.sender].companyName))) {
                balances[i] = updatedClientBalance;
            }
            if (keccak256(bytes(users[addresses[i]].companyName)) == keccak256(bytes(users[supplier].companyName))) {
                balances[i] = updatedSupplierBalance;
            }
        }
    }
       
    // return all transactions in the marketplace
    function getAllTransactions() public view returns (Transaction[] memory) {
        return allTransactions;
    }
}
