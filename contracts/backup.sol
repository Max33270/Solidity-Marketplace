// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;


import "./token.sol";


contract StockContract is ERC20 {
    
    struct Product {
        uint256 id;
        string name;
        uint256 quantity;
        uint256 price;
        uint256 date;
        string companySupplier;
    }

    struct User {
        string companyName;
        string email;
        string password;
        string role;
    }

    struct Transaction {
        uint256 productId;
        address buyer;
        address seller;
        uint256 amount;
        uint256 date;
    }

    uint256 private id;
    mapping(uint256 => Product) private products;
    mapping(address => User) private users;
    mapping(string => bool) private registeredEmails;
    mapping(uint256 => Transaction) private transactions;
    uint256 private transactionId;
    Transaction[] private transactions_history;
    uint256[] private transactionIds;
    ERC20 public token;

    constructor() {
        id = 0;
        transactionId = 0;
    }

    modifier onlySupplier() {
        require(keccak256(bytes(users[msg.sender].role)) == keccak256(bytes("supplier")), "You are not authorized to access this function.");
        _;
    }

    modifier onlyClient() {
        require(keccak256(bytes(users[msg.sender].role)) == keccak256(bytes("client")), "You are not authorized to sell products.");
        _;
    }

    modifier onlyUnregisteredEmail(string memory email) {
        require(!registeredEmails[email], "This email is already registered.");
        _;
    }

    // role supplier or client
    function registerUser(string memory companyName, string memory email, string memory password, string memory role) public onlyUnregisteredEmail(email) {
        // Check Company name
        require(bytes(companyName).length > 0 && bytes(companyName).length < 15, "Company Name is required and must be less than 15 characters.");
        require(bytes(password).length > 0, "Password is required.");
        
        // Check Email
        require(bytes(email).length > 0 && bytes(email).length <= 30, "Email is required and must be less than 50 characters.");
        
        //check if email contain @ and .
        bool atFound = false;
        bool dotFound = false;
        for (uint256 i = 0; i < bytes(email).length; i++) {
            if (bytes(email)[i] == "@") {
                atFound = true;
            }
            if (bytes(email)[i] == ".") {
                dotFound = true;
            }
        }
        require(atFound && dotFound, "Email must contain @ and .");

        // Check Role
        require(keccak256(bytes(role)) == keccak256(bytes("supplier")) || keccak256(bytes(role)) == keccak256(bytes("client")), "Role must be supplier or client.");

        User memory newUser = User(companyName, email, password, role);
        users[msg.sender] = newUser;
        registeredEmails[email] = true;
    }

    function loginUser(string memory email, string memory password) public view returns (bool) {
        if (registeredEmails[email] && keccak256(bytes(users[msg.sender].password)) == keccak256(bytes(password))) {
            return true;
        } else {
            return false;
        }
    }

    function addProduct(string memory name, uint256 quantity, uint256 price, string memory companySupplier) public onlySupplier() {
        id++;
        uint256 date = block.timestamp;
        Product memory newProduct = Product(id, name, quantity, price, date, companySupplier);
        products[id] = newProduct;
    } 

    function updateProduct(uint256 productId, uint256 quantity, uint256 price) public onlySupplier() {
        Product storage product = products[productId];
        require(keccak256(bytes(product.companySupplier)) == keccak256(bytes(users[msg.sender].companyName)), "You are not authorized to update this product.");
        if (quantity != 0) {
            product.quantity = quantity;
        }
        if (price != 0) {
            product.price = price;
        }
    }

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

    function searchProducts(string memory searchString) public view returns (Product[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= id; i++) {
            if (bytes(products[i].name).length != 0 && (keccak256(bytes(products[i].name)) == keccak256(bytes(searchString)) || keccak256(bytes(products[i].
            companySupplier)) == keccak256(bytes(searchString)))) {
                count++;
            }
        }
        Product[] memory foundProducts = new Product[](count);
        uint256 j = 0;
        for (uint256 i = 1; i <= id; i++) {
            if (bytes(products[i].name).length != 0 && (keccak256(bytes(products[i].name)) == keccak256(bytes(searchString)) || keccak256(bytes(products[i].
            companySupplier)) == keccak256(bytes(searchString)))) {
                foundProducts[j] = products[i];
                j++;
            }
        }
        return foundProducts;
    }

    function deleteProduct(uint256 productId) public {
        Product storage product = products[productId];
        require(keccak256(bytes(product.companySupplier)) == keccak256(bytes(users[msg.sender].companyName)), "You are not authorized to delete this product.");
        delete products[productId];
    }

// ************************** obtainProduct() function is not working properly. **************************
    function obtainProduct(uint256 productId) public onlyClient() {
        require(productId <= id, "Product does not exist.");
        Product storage product = products[productId];
        require(product.quantity > 0, "Product is out of stock.");
        product.quantity--;
        transactionId++;
        Transaction memory newTransaction = Transaction(productId, msg.sender, msg.sender, product.price, block.timestamp);
        transactions[transactionId] = newTransaction;
    } 

    function getTransactions() public view returns (Transaction[] memory) {
        Transaction[] memory allTransactions = new Transaction[](transactionIds.length);
        for (uint256 i = 0; i < transactionIds.length; i++) {
            allTransactions[i] = transactions[transactionIds[i]];
        }
        return allTransactions;
    }
}  