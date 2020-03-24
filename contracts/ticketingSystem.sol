pragma solidity >=0.5 ;

import "./ERC20.sol";

abstract contract ticketingSystem is ERC20 {

    struct Artist{
        bytes32 name;
        uint category;
        uint totalTicketSold;
        address payable owner;
    }

    event NewArtist(bytes32 _name, uint _type, uint _totalTicketSold,address payable owner);
    event NewVenue(bytes32 _name, uint _capacity, uint _standardComission, address _owner);
    event NewConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice, address _owner);
    event NewTicket(uint _concertId, address _ticketOwner);
    mapping(uint=>Venue) IdToVenue;
    mapping(uint => Artist) IdToArtist;
    mapping(uint=> Concert) IdToConcert;
    mapping(uint=> Ticket) IdToTicket;
    Artist[] public artistsRegister;
    Venue[] public venuesRegister;
    Concert[] public concertsRegister;
    Ticket[] public ticketsRegister;

    function createArtist(bytes32 _name, uint _typ) public returns(uint){
        Artist memory A = Artist(_name, _typ, 0, msg.sender);
        artistsRegister.push(A);
        uint id = artistsRegister.length;
        IdToArtist[id] = A;
        emit NewArtist(_name, _typ, 0, msg.sender);
    }

    function modifyArtist(uint _artistId, bytes32 _name, uint _artistCategory, address payable _newOwner)
    public OnlyOwnerArtist(_artistId){
        IdToArtist[_artistId].name = _name;
        IdToArtist[_artistId].category = _artistCategory;
        artistsRegister[_artistId].owner = _newOwner;
    }

    struct Venue{
        bytes32 name;
        uint capacity;
        uint standardComission;
        address payable owner;
    }

    struct Concert{
        uint date;
        uint artistId;
        uint ticketPrice;
        uint totalSoldTicket;
        uint totalMoneyCollected;
        uint venueId;
        bool validatedByArtist;
        bool validatedByVenue;
        address payable owner;
    }

    struct Ticket{
        uint concertId;
        address ticketOwner;
        bool isAvailable;
        bool isAvailableForSale;
    }

    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public{
        bool validatedByArtist = false;
        if( msg.sender == IdToArtist[_artistId].owner){
            validatedByArtist = true;
        }
        bool validatedByVenue = false;
        if( msg.sender == IdToVenue[_venueId].owner){
            validatedByVenue = true;
        }
        Concert memory C = Concert(_concertDate, _artistId, _ticketPrice, 0, 0, _venueId, validatedByArtist, validatedByVenue, msg.sender);
        concertsRegister.push(C);
        IdToConcert[concertsRegister.length] = C;
        emit NewConcert(_artistId, _venueId, _concertDate, _ticketPrice,  msg.sender);
    }

    function createVenue(bytes32 _name, uint _capacity, uint _standardComission) public {
        Venue memory V = Venue(_name, _capacity,_standardComission, msg.sender);
        venuesRegister.push(V);
        IdToVenue[venuesRegister.length] = V;
        emit NewVenue(_name, _capacity, _standardComission, msg.sender);
    }

    function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner)
    public OnlyOwnerVenue(_venueId){
        IdToVenue[_venueId].name = _name;
        IdToVenue[_venueId].owner = _newOwner;
        IdToVenue[_venueId].capacity = _capacity;
        IdToVenue[_venueId].standardComission = _standardComission;
    }

    modifier OnlyOwnerArtist(uint _artistId) {
        require(artistsRegister[_artistId].owner == msg.sender, "You are not the owner.");
        _;
    }
    modifier OnlyOwnerConcert(uint _concertId) {
        require(concertsRegister[_concertId].owner == msg.sender, "You are not the owner.");
        _;
    }
    modifier OnlyOwnerVenue(uint _venueId) {
        require(venuesRegister[_venueId].owner == msg.sender, "You are not the owner.");
        _;
    }
    modifier OnlyOwnerTicket(uint _ticketId) {
        require(ticketsRegister[_ticketId].ticketOwner == msg.sender, "You are not the owner.");
        _;
    }

    function validateConcert(uint _concertId) public OnlyOwnerArtist(concertsRegister[_concertId].artistId)
    OnlyOwnerVenue(concertsRegister[_concertId].venueId){
        if(artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender){
            concertsRegister[_concertId].validatedByArtist = true;
        }
        if(venuesRegister[concertsRegister[_concertId].venueId].owner == msg.sender){
            concertsRegister[_concertId].validatedByVenue = true;
        }

    }

    function emitTicket(uint _concertId, address payable _ticketOwner) public OnlyOwnerArtist(concertsRegister[_concertId].artistId){
        Ticket memory T = Ticket(_concertId, _ticketOwner, false, false);
        ticketsRegister.push(T);
        IdToTicket[ticketsRegister.length] = T;
        emit NewTicket(_concertId, _ticketOwner);
    }


    function useTicket(uint _ticketId) public OnlyOwnerTicket(_ticketId){
        if(block.timestamp >= concertsRegister[ticketsRegister[_ticketId].concertId].date - 1 days &&
        block.timestamp <= concertsRegister[ticketsRegister[_ticketId].concertId].date){
            ticketsRegister[_ticketId].isAvailable = true;
        }
    }

    function buyTicket(uint _concertId) public payable{
        require(msg.value == concertsRegister[_concertId].ticketPrice, "Not the good price for ticket.");
        concertsRegister[_concertId].owner.transfer(msg.value);
        concertsRegister[_concertId].totalSoldTicket = concertsRegister[_concertId].totalSoldTicket.add(1);
        concertsRegister[_concertId].totalMoneyCollected = concertsRegister[_concertId].totalMoneyCollected.add(msg.value);
        artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold = artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold.add(1);
        emitTicket(_concertId, msg.sender);
    }

    function transferTicket(uint _ticketId, address payable _newOwner) public OnlyOwnerTicket(_ticketId){
        _transfer2(msg.sender, _newOwner, _ticketId);
    }

    function _transfer2(address _from, address _to, uint _ticketId) public payable {
        ticketsRegister[_ticketId].ticketOwner = _to;
        emit Transfer(_from, _to, _ticketId);
    }

    function cashOutConcert(uint _concertId, address payable _cashOutAddress) public payable OnlyOwnerConcert(_concertId) {
        require(block.timestamp >= concertsRegister[_concertId].date, "You can't cash out now.");
        require(msg.value == concertsRegister[_concertId].totalMoneyCollected, "You didn't gave the exact amount of money");
        _cashOutAddress.transfer(msg.value * venuesRegister[concertsRegister[_concertId].venueId].standardComission / 10000);
        venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(msg.value - msg.value * venuesRegister[concertsRegister[_concertId].venueId].standardComission / 10000);

    }

    function offerTicketForSale(uint _ticketId, uint _salePrice) public payable{
        require(ticketsRegister[_ticketId].ticketOwner == msg.sender, "You are not the owner");
        require(msg.value == _salePrice, "Not the exact amount of money");
        require(_salePrice <= concertsRegister[ticketsRegister[_ticketId].concertId].ticketPrice, "The amount is higher than the initial price.");
        require(ticketsRegister[_ticketId].isAvailable, "The ticket is already used");
        
    }

    function buySecondHandTicket(uint _ticketId) public {
        
    }

}
