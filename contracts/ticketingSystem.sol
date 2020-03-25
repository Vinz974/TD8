pragma solidity >=0.5 ;
pragma experimental ABIEncoderV2;

contract ticketingSystem {

    struct Artist{
        bytes32 name;
        uint artistCategory;
        uint totalTicketSold;
        address owner;
        address payable payad;
    }

    event NewArtist(bytes32 _name, uint _type, uint _totalTicketSold,address payable owner);
    event NewVenue(bytes32 _name, uint _capacity, uint _standardComission, address _owner);
    event NewConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice, address _owner);
    event NewTicket(uint _concertId, address _ticketOwner);
    uint VenueCount =1;
    uint ArtistCount =1;
    uint ConcertCount =1;
    uint TicketCount =1;
    mapping(uint => Artist) artistsRegistered;
    mapping(uint => Venue) venuesRegistered;
    mapping(uint => Concert) concertsRegistered;
    mapping(uint => Ticket) ticketsRegistered;

    function createArtist(bytes32 _name, uint _typ) public returns(uint){
        Artist memory A = Artist(_name, _typ, 0, msg.sender, msg.sender);
        artistsRegistered[ArtistCount] = A;
        ArtistCount = ArtistCount + 1;
        emit NewArtist(_name, _typ, 0, msg.sender);
    }

    function modifyArtist(uint _artistId, bytes32 _name, uint _artistCategory, address payable _newOwner)
    public OnlyOwnerArtist(_artistId){
        artistsRegistered[_artistId].name = _name;
        artistsRegistered[_artistId].artistCategory = _artistCategory;
        artistsRegistered[_artistId].owner = _newOwner;
    }
    struct Venue{
        bytes32 name;
        uint capacity;
        uint standardComission;
        address owner;
        address payable payad;
    }

    struct Concert{
        uint concertDate;
        uint artistId;
        uint ticketPrice;
        uint totalSoldTicket;
        uint totalMoneyCollected;
        uint venueId;
        bool validatedByArtist;
        bool validatedByVenue;
        address owner;
        address payable payad;
    }

    struct Ticket{
        uint concertId;
        address owner;
        address payable payad;
        bool isAvailable;
        bool isAvailableForSale;
        uint amountPaid;
    }

    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public{
        bool validatedByArtist = false;
        if( msg.sender == artistsRegistered[_artistId].owner){
            validatedByArtist = true;
        }
        bool validatedByVenue = false;
        if( msg.sender == venuesRegistered[_venueId].owner){
            validatedByVenue = true;
        }
        Concert memory C = Concert(_concertDate, _artistId, _ticketPrice, 0, 0,
        _venueId, validatedByArtist, validatedByVenue, msg.sender, msg.sender);
        concertsRegistered[ConcertCount] = C;
        ConcertCount = ConcertCount + 1;
        emit NewConcert(_artistId, _venueId, _concertDate, _ticketPrice,  msg.sender);
    }

    function createVenue(bytes32 _name, uint _capacity, uint _standardComission) public {
        Venue memory V = Venue(_name, _capacity,_standardComission, msg.sender, msg.sender);
        venuesRegistered[VenueCount] = V;
        VenueCount = VenueCount + 1;
        emit NewVenue(_name, _capacity, _standardComission, msg.sender);
    }

    function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner)
    public OnlyOwnerVenue(_venueId){
        venuesRegistered[_venueId].name = _name;
        venuesRegistered[_venueId].owner = _newOwner;
        venuesRegistered[_venueId].capacity = _capacity;
        venuesRegistered[_venueId].standardComission = _standardComission;
    }

    modifier OnlyOwnerArtist(uint _artistId) {
        require(artistsRegistered[_artistId].owner == msg.sender, "You are not the owner.");
        _;
    }
    modifier OnlyOwnerConcert(uint _concertId) {
        require(concertsRegistered[_concertId].owner == msg.sender, "You are not the owner.");
        _;
    }
    modifier OnlyOwnerVenue(uint _venueId) {
        require(venuesRegistered[_venueId].owner == msg.sender, "You are not the owner.");
        _;
    }
    modifier OnlyOwnerTicket(uint _ticketId) {
        require(ticketsRegistered[_ticketId].owner == msg.sender, "You are not the owner.");
        _;
    }

    function validateConcert(uint _concertId) public {
        if(artistsRegistered[concertsRegistered[_concertId].artistId].owner == msg.sender){
            concertsRegistered[_concertId].validatedByArtist = true;
        }
        if(venuesRegistered[concertsRegistered[_concertId].venueId].owner == msg.sender){
            concertsRegistered[_concertId].validatedByVenue = true;
        }

    }

    function emitTicket(uint _concertId, address payable _ticketOwner) public {
        require(msg.sender == artistsRegistered[concertsRegistered[_concertId].artistId].owner, "Problem");
        Ticket memory T = Ticket(_concertId,_ticketOwner, _ticketOwner, true, false,concertsRegistered[_concertId].ticketPrice);
        ticketsRegistered[TicketCount] = T;
        TicketCount = TicketCount + 1;
        concertsRegistered[_concertId].totalSoldTicket = concertsRegistered[_concertId].totalSoldTicket + 1;
        emit NewTicket(_concertId, _ticketOwner);
    }

    function emitTicket2(uint _concertId, address _ticketOwner) public {
        Ticket memory T = Ticket(_concertId,_ticketOwner, msg.sender, true, false,concertsRegistered[_concertId].ticketPrice);
        ticketsRegistered[TicketCount] = T;
        TicketCount = TicketCount + 1;
        concertsRegistered[_concertId].totalSoldTicket = concertsRegistered[_concertId].totalSoldTicket + 1;
        emit NewTicket(_concertId, _ticketOwner);
    }


    function useTicket(uint _ticketId) public {
        require (msg.sender == ticketsRegistered[_ticketId].owner, "Problem");
        require (block.timestamp >= concertsRegistered[ticketsRegistered[_ticketId].concertId].concertDate - 1 days &&
        block.timestamp <= concertsRegistered[ticketsRegistered[_ticketId].concertId].concertDate, "Problem");
            ticketsRegistered[_ticketId].isAvailable = false;
    }

    function buyTicket(uint _concertId) public payable{
        require(msg.value == concertsRegistered[_concertId].ticketPrice, "Not the good price for ticket.");
        concertsRegistered[_concertId].payad.transfer(msg.value);
        concertsRegistered[_concertId].totalMoneyCollected = concertsRegistered[_concertId].totalMoneyCollected + msg.value;
        uint intermediary = artistsRegistered[concertsRegistered[_concertId].artistId].totalTicketSold + 1;
        artistsRegistered[concertsRegistered[_concertId].artistId].totalTicketSold = intermediary;
        emitTicket2(_concertId, msg.sender);
    }

    function transferTicket(uint _ticketId, address payable _newOwner) public OnlyOwnerTicket(_ticketId){
        ticketsRegistered[_ticketId].owner = _newOwner;
    }

    function cashOutConcert(uint _concertId, address payable _cashOutAddress) public {
        require(block.timestamp >= concertsRegistered[_concertId].concertDate, "You can't cash out now.");
        uint inte = concertsRegistered[_concertId].totalMoneyCollected;
        artistsRegistered[concertsRegistered[_concertId].artistId].payad
        .transfer(inte * venuesRegistered[concertsRegistered[_concertId].venueId].standardComission / 10000);
        venuesRegistered[concertsRegistered[_concertId].venueId].payad.transfer(
            inte - inte * venuesRegistered[concertsRegistered[_concertId].venueId].standardComission / 10000);
    }

    mapping(uint=> uint) salePrices;

    function offerTicketForSale(uint _ticketId, uint _salePrice) public {
        require(ticketsRegistered[_ticketId].owner == msg.sender, "You are not the owner");
        require(_salePrice <= concertsRegistered[ticketsRegistered[_ticketId].concertId].ticketPrice,
        "The amount is higher than the initial price.");
        require(ticketsRegistered[_ticketId].isAvailable, "The ticket is already used");
        ticketsRegistered[_ticketId].isAvailableForSale = true;
        salePrices[_ticketId] = _salePrice;
    }

    function buySecondHandTicket(uint _ticketId) public payable{
        require(msg.value == salePrices[_ticketId], "Not the exact amount of money");
        require(ticketsRegistered[_ticketId].isAvailable, "Ticket already used.");
        ticketsRegistered[_ticketId].payad.transfer(msg.value);
        ticketsRegistered[_ticketId].isAvailableForSale = false;
        ticketsRegistered[_ticketId].owner = msg.sender;
    }

    function artistsRegister( uint Id) public view returns(Artist memory) {
        return artistsRegistered[Id];
    }

    function concertsRegister( uint Id) public view returns(Concert memory) {
        return concertsRegistered[Id];
    }

    function venuesRegister( uint Id) public view returns(Venue memory) {
        return venuesRegistered[Id];
    }

    function ticketsRegister( uint Id) public view returns(Ticket memory) {
        return ticketsRegistered[Id];
    }
}
