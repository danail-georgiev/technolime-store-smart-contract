// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

interface ITechnoLimeStore {

    /**
     * @notice Function used to add products in the Store
     * @param productName - product name as string which is added to the Store inventory
     * @param quantity - product quantity which is added to the Store
     */
    function addProduct(string memory productName, uint quantity) external;

    /**
     * @notice Function used to show all the available Products in the store with quantity greatwer than 0
     * @return Array of strings for the available products
     */
    function getStoreAvailableProducts() external view returns(string[] memory);

    /**
     * @notice Function used for buying products By Product Id
     * @param productId of the Product being bought
     * @param quantity of the product to be bought
     */
    function buyProductById(uint productId, uint quantity) external;

    /**
     * @notice Function used for returning products in specified time frame
     * @param productName - name of the returned product
     * @param productQuantity - number of items of the product to be returned
     */
    function returnProduct(string memory productName, uint productQuantity) external;

    /**
     * @notice Function showing all the addresses which has bought a specific Product
     * @param productName - name of the Product from the store
     * @return Array with buyers addresses
     */
    function getCustomerAddressesByProductBought(string memory productName) external view returns (address[] memory);
}

contract TechnoLimeStore is Ownable, ITechnoLimeStore{

    //Time duration of the Return Product Policy
    uint private constant DURATION = 100;
    //Number of products in store, used for assigning Ids to the store products
    uint private productCount;

    event ProductBought(string productName, uint productId, string logMessage);
    event ProductReturned(string productName, uint productId, string logMessage);
    event NewProductAdded(string productName, uint productId, string logMessage);
    event UpdateProductQuantity(string productName, uint quantity, string logMessage);

    error NoProductInventory(string productName, uint productId, string logMessage);

    //Struct describing a produst with all the respective info assciated with it
    struct Product {
        uint id;
        string name;
        uint quantity;
        //buyers address associated with buyers timestamps used for Return product policy
        mapping(address => uint) productBoughtTimestamps;
        //buyers addresses for each product in the store
        address[] buyersAddresses;
    }

    Product[] private products;

    //used to map product name to Product struct
    mapping(string => Product) public productsInStore;

    constructor() {
    }

    modifier onlyIfProductExistsInStore(string memory productName) {
        require(bytes(productsInStore[productName].name).length != 0, "Product Does Not Exist In the Store!");
        _;
    }


    //@notice - function implementing add product functionality for the store products
	function addProduct(string memory productName, uint quantity) external onlyOwner {
        require(quantity > 0, "The added product quantity must be greater than 0");

        if (productsInStore[productName].quantity > 0) {
            updateProductQuantity(productName, quantity);

            emit UpdateProductQuantity(productName, quantity, "Product Quantity Updated!");
            return;
        }

        setNewProductInStorageArray(productName, quantity);
        setNewProductInStorageMapping(productName, quantity);

        productCount++;

        emit NewProductAdded(productName, productCount, "Product Added!");
    }

    function getStoreAvailableProducts() external view returns(string[] memory) {

        string[] memory availableProducts = new string[](productCount);
        uint counter = 0;

        //Only show products which are in stock (quantity greater than 0)
        for (uint i = 0; i < products.length; i++) {
            if (products[i].quantity > 0) {
                availableProducts[counter] = products[i].name;
                counter++;
            }
        }
        return availableProducts;
    }

    //@notice - function implementing buying the product functionality by id
    function buyProductById(uint productId, uint quantity) external onlyIfProductExistsInStore(products[productId].name) {
        require(quantity > 0, "The quantity of the products bought must be greater than 0");

        Product storage product = products[productId];
        products.push();


        require(product.productBoughtTimestamps[msg.sender] == 0, "A product cannot be bought more than once by a customer!");

        if (product.quantity < quantity) {
            revert NoProductInventory(product.name, productId, "Not enough product inventory!");
        }

        product.quantity-=quantity;
        product.buyersAddresses.push(msg.sender);
        product.productBoughtTimestamps[msg.sender] = block.timestamp;

        emit ProductBought(product.name, product.quantity, "One more Product was bought!");
    }

    //@notice - function implementing returning the product within certain Time frame
    function returnProduct(string memory productName, uint productQuantity) external onlyIfProductExistsInStore(productName) {

        Product storage product = productsInStore[productName];
        product = products[product.id];

        require(product.productBoughtTimestamps[msg.sender] != 0, "A product cannot be returned before being bought!");
        require(block.timestamp - product.productBoughtTimestamps[msg.sender] > 100000000000000000000, "The time frame for returning the product has expired");

        product.quantity+=productQuantity;
        emit ProductReturned(productName, product.id, "The Product has been returned!");
    }

    function getCustomerAddressesByProductBought(string memory productName) external view onlyIfProductExistsInStore(productName) returns (address[] memory) {
        return products[productsInStore[productName].id].buyersAddresses;
    }

    //*******
    //Internal utilities to follow
    //********
    function updateProductQuantity(string memory productName, uint quantity) internal {
            Product storage product = productsInStore[productName];
            product.quantity += quantity;
            emit UpdateProductQuantity(productName, quantity, "Product Quantity Updated!");
    }

    function setNewProductInStorageArray(string memory productName, uint quantity) internal {
            Product storage product = products.push();

            product.id = productCount;
            product.name = productName;
            product.quantity = quantity;
    }

    function setNewProductInStorageMapping(string memory productName, uint quantity) internal {
            Product storage product = productsInStore[productName];

            product.id = productCount;
            product.name = productName;
            product.quantity = quantity;
    }
}