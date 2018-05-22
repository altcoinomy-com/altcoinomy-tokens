pragma solidity ^0.4.19;

/*
 * Wine HToken
 *
 *
 * 2018
 */


/**
 * @title SafeMath
 * @notice Math operations with safety checks that throw on error
 */
contract SafeMath {

    /**
     * @notice Add two numbers, throw on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assert((c = a + b) >= a);
    }

   /**
     * @notice Subtract two numbers, throw on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(a >=b);
        assert((c = a - b) <= a);
    }
    
}

contract Administered {
    
    // bool public presaleRegistrationIsOpen;
    // bool public saleRegistrationIsOpen;
    // bool public revolvingsaleRegistrationIsOpen;
    // bool public presaleTokenMintageAndDistributionIsOpen;
    // bool public revolvingsaleTokenMintageAndDistributionIsOpen;
    // 

    address public owner;
    address public ownerNext;
    address public notary;
    address public governor;
    address public rescuer;

    event UpdatedOwner (address indexed oldOwner, address indexed newOwner);
    event UpdatedNotary (address indexed oldNotary, address indexed newNotary);
    event UpdatedGovernor (address indexed oldGovernor, address indexed newGovernor);
    event UpdatedRescuer (address indexed oldRescuer, address indexed newRescuer);

    function Administered() public {
        owner = msg.sender;
	ownerNext = address(0);
        notary = msg.sender;
        governor = msg.sender;
        rescuer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotary {
        require(msg.sender == notary);
        _;
    }
    
    modifier onlyGovernor {
        require(msg.sender == governor);
        _;
    }
    
    modifier onlyRescuer {
        require(msg.sender == rescuer);
        _;
    }

    function updateOwner(address _newOwner) onlyOwner public {
        ownerNext = _newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == ownerNext);
        address ex = owner;
        owner = ownerNext;
        ownerNext = address(0);
        UpdatedOwner(ex, owner);
    }
    
    function updateNotary(address _newNotary) onlyOwner public {
        address ex = notary;
        notary = _newNotary;
        UpdatedNotary(ex, notary);
    }
    
    function updateGovernor(address _newGovernor) onlyOwner public {
        address ex = governor;
        governor = _newGovernor;
        UpdatedGovernor(ex, governor);
    }
    
    function updateRescuer(address _newRescuer) onlyOwner public {
        address ex = rescuer;
        rescuer = _newRescuer;
        UpdatedRescuer(ex, rescuer);
    }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function balanceOf(address _owner) public view returns (uint256);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }




contract TokenERC20 is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Save this for an assertion in the future
        uint256 previousBalances = add(balanceOf[_from], balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = sub(balanceOf[_from], _value);
        // Add the same to the recipient
        balanceOf[_to] = add(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in the code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * @notice Transfer `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * @notice Transfers `_value` tokens to `_to` in behalf of `_from` (if allowed)
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender] ,_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * @notice Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

}

contract WineToken is Administered, TokenERC20 {
    
    //uint256 public sellPrice;
    //uint256 public buyPrice;

    //mapping (address => bool) public frozenAccount;

    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event EmergencyTransfer(address indexed from, address indexed to, uint256 value);
    
    event Notarize(string str);

    /* This generates a public event on the blockchain that will notify clients */
    //event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract
    function WineToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    */    

    function WineToken(
    ) TokenERC20(0, "Wine HToken", "WINE") public {}

    /* Internal transfer, only can be called by this contract */
    /* 
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        //require(!frozenAccount[_from]);                     // Check if sender is frozen
        //require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }
    */

/**
     * @notice Create `_value` tokens and send it to `_target`
     * @param _target Address to receive the tokens
     * @param _value the amount of tokens it will receive
     */
    function mint(address _target, uint256 _value) onlyGovernor public returns (bool success) {
        balanceOf[_target] = add(balanceOf[_target], _value);
        totalSupply = add(totalSupply, _value);
        Transfer(0, _target, _value);
        Mint(this, _target, _value);
        return true;
    }

   /**
     * @notice Destroys `_value` tokens from sender's account
     * @param _value the amount of tokens to burn
     */
    function burn(uint256 _value) onlyGovernor public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
        totalSupply = sub(totalSupply, _value);
        Transfer(msg.sender, 0, _value);
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * @notice Destroys `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _value the amount of tokens to burn
     */
    function burnFrom(address _from, uint256 _value) onlyGovernor public returns (bool success) {
        require(balanceOf[_from] >= _value);                                                   // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);                                       // Check allowance
        balanceOf[_from] = sub(balanceOf[_from], _value);                                      // Subtract from the targeted balance
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value);              // Subtract from the sender's allowance
        totalSupply = sub(totalSupply, _value);                                                // Update totalSupply
        Transfer(_from, 0, _value);
        Burn(_from, _value);
        return true;
    }

   /**
     * @notice Transfer `_value` tokens to `_to` from `_from` account
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function emergencyTransfer(address _from, address _to, uint256 _value) onlyRescuer public {
        _transfer(_from, _to, _value);
        EmergencyTransfer(_from, _to, _value);
    }

    // variable stored in the smart contract memory
    string public notarizedIpfsHash = '';

    function cmpStrings (string str1, string str2) internal pure returns (bool){
        return keccak256(str1) == keccak256(str2);
    }
    
    // notarization: write input hash into smart contract memory (transactional function)
    function writeNotarizedIpfsHash (string _hash) public onlyNotary returns (bool) {
        notarizedIpfsHash = _hash;
        Notarize(_hash);
        return true;
    }
    
    // notarization: read smart contract memory (constant function)
    function readNotarizedIpfsHash() public constant returns (string) {
        return notarizedIpfsHash;
    }
    
    // notarization: check input hash against smart contract memory (constant function)
    function checkNotarizedIpfsHash(string _hash) public constant returns (bool) {
        return cmpStrings(_hash, notarizedIpfsHash);
    }

    // Allow transfer of accidentally sent ERC20 tokens
    function refundTokens(address _recipient, address _token) public onlyOwner {
        require(_token != address(this));
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(this);
        require(token.transfer(_recipient, balance));
    }


    function kill() onlyOwner public {
        selfdestruct(owner);
    }
    
}
