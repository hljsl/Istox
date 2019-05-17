pragma experimental ABIEncoderV2;

library Utils {
    struct Shopper {
        bool exists;
        uint age;
        uint usd_balance;
        uint token_balance;
        uint orderNumber;
        bool isFemale;
        bool isElite;
    }
}

contract Product {
    
    
      modifier onlyOwner() {
        require(msg.sender == owner);
        _;
      }
  
    uint price;
    address public owner;

    constructor(uint _price) public {
        owner = msg.sender;
        price = _price;
    }
    
    function getPrice() public view returns (uint) {
        return price;
    }

    function setPrice(uint _price) public onlyOwner returns (bool success) {
        price = _price;
        return true;
    }
    
    function canBuy(Utils.Shopper memory customer) public returns (bool success);
    
    function canReturn(uint purchaseDate) public returns (bool success);
}

contract Skirt is Product {
    constructor(uint _price) public Product(_price) {}
    
    function canBuy(Utils.Shopper memory customer) public returns (bool success) {
        return customer.isFemale;
    }
    
    function canReturn(uint purchaseDate) public returns (bool success) {
        return (now - purchaseDate * 1 days) < 22 days;
    }
}

contract Alcohol is Product {
    constructor(uint _price) public Product(_price) {}
    
    function canBuy(Utils.Shopper memory customer) public returns (bool success) {
        return customer.age > 20;
    }
    
    function canReturn(uint purchaseDate) public returns (bool success) {
        return (now - purchaseDate * 1 days) < 22 days;
    }
}

contract StrongAlcohol is Product {
    constructor(uint _price) public Product(_price) {}
    
    function canBuy(Utils.Shopper memory customer) public returns (bool success) {
        return customer.age > 80;
    }
    
    function canReturn(uint purchaseDate) public returns (bool success) {
        return (now - purchaseDate * 1 days) < 22 days;
    }
}

contract Shop  {
    
  modifier onlyOwner() {
    require(msg.sender == o);
    _;
  }
  
    struct Expense {
        address product;
        uint pricePaid;
        uint date;
    }
    
    address public o;

    mapping(address => Utils.Shopper) customers;
    mapping(address => Product) products;
    address[] productList;
    address[] customerList;
    mapping(address => mapping(uint => Expense)) expenses;
    
    uint eliteStatusLimit = 500;

    constructor() public {
        o = msg.sender;
    }
    
    function seeProducts() public view returns (address[] memory) {
        return productList;
    }
    
    function seeCustomer(address id) public view returns (Utils.Shopper memory) {
        return customers[id];
    }
    
    function setEliteStatusLimit(uint limit) public onlyOwner returns (bool){
        eliteStatusLimit = limit;
        return true;
    }
    
    function registerCustomer(uint _age, bool _isFemale, uint money, address _customerId) public onlyOwner returns (bool) {
        if (customers[_customerId].exists) return false;

        customers[_customerId] = Utils.Shopper(true, _age, money, 0, 0, _isFemale, false);
        customerList.push(_customerId);
        return true;
    }
    
    function addCustomerFunds(address _customerId, uint balance) public onlyOwner returns (bool) {
        if (!customers[_customerId].exists) return false;
        
        customers[_customerId].usd_balance += balance;
        return true;
    }
    
    function checkEliteForCustomer(address _customerId) public onlyOwner returns (bool success) {
        uint mothlyExpense = 0;
        for (uint j = customers[_customerId].orderNumber - 1; j >= 0; j--) {
            if (expenses[_customerId][j].date + 30 days > now) {
                mothlyExpense += expenses[_customerId][j].pricePaid;
            } else {
                break;
            }
        }
        customers[_customerId].isElite = (mothlyExpense >= eliteStatusLimit);
        customers[_customerId].token_balance += mothlyExpense;
        return true;
    }
    
    function getCustomerOrder(address id, uint orderId) public view returns (Expense memory) {
        return expenses[id][orderId];
    }
    
    function addProduct(address item) public onlyOwner returns (bool) {
        for (uint i = 0; i < productList.length; i++) {
            if (productList[i] == item) {
                return false;
            }
        }
        products[item] = Product(address(item));
        productList.push(item);
        return true;
    }
    
    function buyProduct(address item, uint _price) public returns (bool success) {
        Product prod = products[item];
        uint price = prod.getPrice();
        require(price == _price);
        
        if (customers[msg.sender].isElite) {
            price -= price / 10;
        }
        require(customers[msg.sender].usd_balance > price );
        
        if (prod.canBuy(customers[msg.sender])) {
            customers[msg.sender].usd_balance -= price;
            Expense memory e;
            e.date = now;
            e.pricePaid = price;
            e.product = item;
            expenses[msg.sender][customers[msg.sender].orderNumber] = e;
            customers[msg.sender].orderNumber++;
            return true;
        } else {
            return false;
        }
    }