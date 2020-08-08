pragma solidity >=0.4.22 <0.7.0;

import "../ERC721/ERC721Metadata.sol";

contract Tyosasyo is ERC721Metadata{

    struct Survey {
        uint256 tokenNumber;
        uint256 tokenGoodCount;
        uint256 tokenValue;
        address mintedby;
        address owner;
        string text;
        bool borrowed;
    }

    
    mapping (uint => Survey) private surveys;
    mapping (uint => address[]) private goodTokenProof;
    mapping (address => uint) ownerTokenCount;
    mapping (address => uint) pendingWithdrawals;

    uint private tokenCounter;
    address private center;

    constructor() public ERC721Metadata("Survey Token System", "STS"){
        tokenCounter = 0;
        center = msg.sender;
    }
    

    
    modifier onlyOwnerOf(uint _tokenId) {
        require(msg.sender == surveys[_tokenId].owner);
        _;
    }
    

    function addToken(string memory uri,string memory str) public {
        tokenCounter++;
        ownerTokenCount[msg.sender]++;
        surveys[tokenCounter] = Survey(tokenCounter,0,1 ether, msg.sender, msg.sender, str, false);
        super._mint(msg.sender,msg.sender, tokenCounter);
        super._setTokenURI(tokenCounter,uri);
    }
    
    //一投稿に一人一回までにする
    function goodToken(uint256 _tokenId) public {
        require(_goodBytoken(_tokenId, msg.sender) == false,"二回目なのでいいねできません");
        surveys[_tokenId].tokenGoodCount = surveys[_tokenId].tokenGoodCount.add(1);
        goodTokenProof[_tokenId].push(msg.sender);
    }
    
    function _goodBytoken(uint _tokenId, address _goodAddress) internal view returns(bool){
        bool result = false;
        for (uint i = 0;i<goodTokenProof[_tokenId].length;i++){
            if(goodTokenProof[_tokenId][i] == _goodAddress){
                result = true;
            }
        }
        return result;
    }

    //発行者がトークンを送信するための関数で購入時にbuyToken関数からしか実行されない
    function _transfer(address to, uint _tokenId) private {
        super._transferFrom(surveys[_tokenId].mintedby, to, _tokenId);
        surveys[_tokenId].borrowed = true;
        surveys[_tokenId].owner = to;
    }
    
    function buyToken(uint256 _tokenId) public payable {
        require(surveys[_tokenId].owner == surveys[_tokenId].mintedby,"トークンが発行者の手元のありません");
        pendingWithdrawals[surveys[_tokenId].mintedby]+=msg.value;
        _transfer(msg.sender,_tokenId);
    }
    
    function withdraw() public {
        require(pendingWithdrawals[msg.sender]!=0,"返金するETHがありません");
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    //トークンを発行者に返す関数
    function returnT(uint _index) public {
        require(
            surveys[_index].borrowed == true && msg.sender != surveys[_index].mintedby && msg.sender == surveys[_index].owner,"あなたはそのトークンの所有者ではありません"
        );
        super._transferFrom(msg.sender, surveys[_index].mintedby, _index);
        surveys[_index].borrowed = false;
        surveys[_index].owner = surveys[_index].mintedby;
    }
    //自己回収
    function MyreturnT(uint _index) public {
        super._transferFrom(surveys[_index].owner,msg.sender, _index);
        surveys[_index].borrowed = false;
        surveys[_index].owner = surveys[_index].mintedby;
    }


    function EditTokenA(uint index, string memory _text) public {
        surveys[index].text = _text;
    }

 function Inquiry(uint index) external view returns (
        uint tokenNumber,
        uint tokenGoodCount,
        uint tokenValue,
        address mintedby,
        address owner,
        string text,
        bool borrowed
        ) {

        Survey memory token = surveys[index];
        //require(msg.sender == token.owner, "トークン発行者はその調査書情報は参照できません");
        tokenNumber = token.tokenNumber;
        tokenGoodCount = token.tokenGoodCount;
        tokenValue = token.tokenValue;
        mintedby = token.mintedby;
        owner = token.owner;
        text = token.text;
        borrowed = token.borrowed;
    }


}
