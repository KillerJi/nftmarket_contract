# nftmarket_contract

## contract

dev endpoint: `http://18.180.227.173:8545/`

#### 合约通用结构体OrderInfo
> struct OrderInfo 

    uint256 订单id
    uint256 nft token id
    uint256 价格
    address 支付币种地址（支付币种类型若为原始币种，则传入0x0000000000000000000000000000000000000000）
    address nft 创建者地址（首次上架平台出售nft的卖家地址）
    address nft owner地址（卖家地址）
    address 买家地址
    uint256 nft开始销售时间戳
    uint256 nft结束销售时间戳
    bool 支付币种类型（true:原始币种， false:erc20币种）
    

### order `0xDe5a05D05a0E730A56159F1b779187265A5D2845`
订单存储合约

**Function**

- orderCompleted(struct OrderInfo):订单成交上传信息

- sellerTakeDown(uint256)：出售者下架订单，由NFTmarket合约调用
    * uint256:订单id
   
**Event**

```solidity
    event OrderCompleted(
        OrderInfo orderinfo
    );
    event SellerTakeDown(uint256 orderid);
```

### nft `0x0EA65B124cE48B5e9d5D1107cf016a0ba1703248`
NFT存储合约

**Function**

- payStatus(address):用户是否支付了上架手续费的标志
    * address:查询的用户地址

- safeTransferFrom(address, address, uint256, uint256, bytes):转移nft
    * address: 拥有者地址
    * address: 接收者地址
    * uint256: nft tokenid
    * uint256: 数量，（默认传1）
    * bytes: （默认传空数组）
  
- safeBatchTransferFrom(address, address, uint256[], uint256[], bytes):批量转移nft
    * address: 拥有者地址
    * address: 接收者地址
    * uint256[]: nft tokenid数组
    * uint256[]: 对应的nft数量数组，（默认全部传1）
    * bytes: （默认传空数组）

- claim(address, uint256):管理员提币（只有owner能调用该函数）
    * address:提币地址
    * uint256:提币数量

- set_listingFee(uint256):管理员设置入场手续费（只有owner能调用该函数）
    * uint256:手续费数量（原生代币为单位，要输入小数位）

- create(address, uint256):创建nft
    * address:创建者地址
    * uint256:tokenid

- settlementfee()：收第一次上架的用户的上架手续费，并且将用户所有nft授权给合约
    * payable，传值默认要大于listingFee，并且该用户没有交过手续费，否则失败


**Event**

```solidity
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event Claim(address add, uint256 num);
    event SettlementFee(address msgsender);
    event Create(address initialOwner, uint256 id);
    event SetListingFee(uint256 fee);
```

### nftmarket `0xfE50823cB3132D8808cD97573C059b32A35E7344`
NFT订单买卖合约

**Function**
交易总手续费率=creatorFee + platformFee
- creatorFee():创作者手续费(/100 如返回100则为1%)

- platformFee():平台手续费(同上)

- buyOrder(OrderInfo, uint8, bytes32, bytes32, address, bool):用户购买订单（这里的RSV由该订单卖家签名）
    * OrderInfo: 订单信息;
    * uint8: V
    * bytes32: R
    * bytes32: S
    * address: nft合约地址
    * bool: nft合约协议类型（1155传true，721传false）
    * payable，若为原生代币订单类型时，该值必须大于等于订单价格
  
- claim(address, uint256):管理员提币（只有owner能调用该函数）
    * address:提币地址
    * uint256:提币数量

- claim_other(address, uint256): 管理员提ERC20币（只有owner能调用该函数）
    * address: claim用户地址
    * uint256: 提取eht数量

- add_currency(address): 增加支付币种（只有owner能调用该函数）
    * address:支付币种

- delete_currency(address): 删除支付币种（只有owner能调用该函数）
    * address:支付币种

- takeDown(address, uint256, bytes32, bytes32, uint8):卖家下架他的出售订单,（这里的RSV由管理员私钥签名）
    * address:卖家的地址
    * uint256:订单id
    * uint8: V
    * bytes32: R
    * bytes32: S
  
**Event**

```solidity
        event BuyOrder(
        uint256 tokenid,
        uint256 price,
        address seller,
        address buyer,
        address nftaddress
    );
    event Claim(address add, uint256 num);
    event ClaimOther(address account, uint256 number);
    event AddCurrency(address account, address token);
    event DeleteCurrency(address account, address token);
    event TakeDown(address signer, uint256 orderid);
```
