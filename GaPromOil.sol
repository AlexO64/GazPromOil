pragma solidity ^0.4.24;
contract OilHankRegistar {
    // Drill - Бурение = 0
    // Lift - Подъем = 1
    // Descent - Спуск = 2
    // DescentColumn - Спуск Колонны = 3
    // Laboring - Проработка = 4
    // Templating - Шаблонировка = 5
    // Reset - перетяжка = 6
    // EmergencyLabor - аварийные работы = 7
    // TechnologySPO - перетяжка = 8
    
    enum ActionChoices { Drill, Lift, Descent, DescentColumn, Laboring, Templating, Reset, EmergencyLabor, SPO, TechnologySPO }
    
    struct OilHank {
        uint registrationTime;
        uint weigthVPS;
        uint candleLength;
        uint registrationMTBF; 
        uint resetMTBF;
        uint lastActionMTBF;
        string oilHankRegName;
    }
   
    struct Action {
        uint regTime;
        uint startLH;
        uint endLH;
        uint startWeigth;
        uint endWeigth;
        ActionChoices action;
    }
   
    ActionChoices constant defaultChoice = ActionChoices.Drill;
   
    address owner; // just in case  if we will need owner later
   
    OilHank[ ] public darOilHank;
    mapping( bytes32 => uint ) public indexOilHank;
    mapping( uint => Action[] ) public dictActions;
    
    event OilHankRegistered( string indexed oilHankRegName, 
        uint index,
        uint registrationTime,
        uint weigthVPS,
        uint candleLength,
        uint registrationMTBF, 
        uint resetMTBF,
        uint lastActionMTBF
    );
    event OilHankExists( string indexed oilHankRegName );
    event OilHankActionRegistered( string indexed oilHankRegName, 
        uint regTime,
        uint startLH,
        uint endLH,
        uint startWeigth,
        uint endWeigth,
        uint action
    );
    
    constructor( ) public {
        // State variables are accessed via their name
        // and not via e.g. this.owner. This also applies
        // to functions and especially in the constructors,
        // you can only call them like that ("internally"),
        // because the contract itself does not exist yet.
        owner = msg.sender;
        
        // we need this registration for later when will be adding Actions
        // Actions cannot be added to ) index

        darOilHank.push( OilHank( 
            {
                registrationTime : 0,
                weigthVPS : 0,
                candleLength : 0,
                registrationMTBF : 0,
                resetMTBF : 0,
                lastActionMTBF : 0,
                oilHankRegName : "zeroIndexOilHank"
            }
        ) );
        
        indexOilHank[ sha256( bytes( darOilHank[ 0 ].oilHankRegName ) ) ] = 0;
        
        emit OilHankRegistered( "zeroIndexOilHank", 0, 0, 0, 0, 0, 0, 0 );
    }
   
    function()public payable {
        if( msg.value != 0 ){
            revert( "Dom't send ether to this contract" );
        }
    }
    
    function getHankOilRegistrationsNumber( )public view returns( uint ){
        return darOilHank.length;
    }
    
    function getHankOilActionsNumber( uint index )public view returns( uint ){
        if( darOilHank.length < index ){
            revert( "index out of range" );
        }
        
        return dictActions[ index ].length;
    }
   
    function getOilHankHash( string oilHankRegName ) public pure returns ( bytes32 ){
        return sha256( bytes( oilHankRegName ) ); // hash Hank RegName
    }

    /*
    mapping( bytes32 => uint ) public indexOilHank;  doing the same with getOilHankHash
    function getOilHankIndex( string oilHankRegName ) public view returns ( uint ){
        return indexOilHank[ sha256( bytes( oilHankRegName ) ) ];
    }
    */
   
    function registerOilHank( uint weigthVPS, uint candleLength, uint registrationMTBF, uint resetMTBF, string oilHankRegName )
    public returns ( uint ){
        if( indexOilHank[ sha256( bytes( oilHankRegName ) ) ] > 0 ){ //if already exists do nothing
            emit OilHankExists( oilHankRegName );
        }else{ // save reg info
            OilHank memory newOilHank;
            newOilHank.registrationTime = now;
            newOilHank.weigthVPS = weigthVPS;
            newOilHank.candleLength = candleLength;
            newOilHank.registrationMTBF = registrationMTBF; 
            newOilHank.resetMTBF = resetMTBF;
            newOilHank.lastActionMTBF = registrationMTBF;
            newOilHank.oilHankRegName = oilHankRegName;
            darOilHank.push( newOilHank );
            indexOilHank[ sha256( bytes( oilHankRegName ) ) ] = darOilHank.length - 1;
            emit OilHankRegistered( oilHankRegName,
                darOilHank.length - 1,
                now,
                weigthVPS,
                candleLength,
                registrationMTBF, 
                resetMTBF,
                registrationMTBF
            );
        }
        return darOilHank.length - 1;
    }
   
    function getOilHankInfo( string oilHankRegName ) public view returns( 
        uint registrationTime,
        uint weigthVPS, 
        uint candleLength, 
        uint registrationMTBF, 
        uint resetMTBF, 
        uint lastActionMTBF
    ){
        uint idx = indexOilHank[ sha256( bytes( oilHankRegName ) ) ]; 
        
        registrationTime = darOilHank[ idx ].registrationTime;
        weigthVPS = darOilHank[ idx ].weigthVPS;
        candleLength = darOilHank[ idx ].candleLength;
        registrationMTBF = darOilHank[ idx ].registrationMTBF;
        resetMTBF = darOilHank[ idx ].resetMTBF;
        lastActionMTBF = darOilHank[ idx ].lastActionMTBF;
        
        return;
    }
    
    function calculateStepLabour( uint weigthVPS, uint candleLength, uint stepWeigth, uint stepLength ) public pure returns( uint ){
        return( 
            ( stepWeigth * ( stepLength + candleLength ) ) +
            ( 4 * weigthVPS * stepLength )
        ) / 100000;
    }
    
    function absDifference( uint startStep, uint stopStep ) public pure returns( uint ){
        if( startStep >= stopStep ){
            return startStep - stopStep;
        }
        return stopStep - startStep;
    }
    
    function calculateActionValue( uint action, uint startStep, uint stopStep ) public pure returns( uint ){
        //{ Drill, Lift, Descent, DescentColumn, Laboring, Templating, Reset, EmergencyLabor, SPO, TechnologySPO }
        // Fromula for calculation
        //IF RC[-9]="Подъем",                   ABS(RC[-1]-RC[-2])*0.5
        //IF RC[-9]="Спуск",                    ABS(RC[-1]-RC[-2])*0.5
        //IF RC[-9]="СПО",                      ABS(RC[-1]-RC[-2])
        //IF RC[-9]="Бурение",                  ABS(RC[-1]-RC[-2])*3
        //IF RC[-9]="Отбор керна",              ABS(RC[-1]-RC[-2])*2
        //IF RC[-9]="Проработка",               ABS(RC[-1]-RC[-2])*2
        //IF RC[-9]="Шаблонировка",             ABS(RC[-1]-RC[-2])*2
        //IF RC[-9]="Спуск обсадной колонны",   RC[-1]*0.5
        //IF RC[-9]="Технологическое СПО",      ABS(RC[-1]-RC[-2])
        //IF RC[-9]="Аварийные работы",         RC[-1]*2
        
        require(uint(ActionChoices.TechnologySPO) >= action);
        ActionChoices operation = ActionChoices( action );
        
        //IF RC[-9]="Бурение",                  ABS(RC[-1]-RC[-2])*3
        if( operation == ActionChoices.Drill ){
            return absDifference( stopStep, startStep ) * 3;
        }
        
        //IF RC[-9]="Подъем",                   ABS(RC[-1]-RC[-2])*0.5
        //IF RC[-9]="Спуск",                    ABS(RC[-1]-RC[-2])*0.5
        if( operation == ActionChoices.Lift || operation == ActionChoices.Descent ){
            return absDifference( stopStep, startStep ) / 2;
        }
        
        //IF RC[-9]="СПО",                      ABS(RC[-1]-RC[-2])
        //IF RC[-9]="Технологическое СПО",      ABS(RC[-1]-RC[-2])
        if( operation == ActionChoices.SPO || operation == ActionChoices.TechnologySPO ){
            return absDifference( stopStep, startStep );
        }
        
        //IF RC[-9]="Аварийные работы",         RC[-1]*2
        if( operation == ActionChoices.EmergencyLabor ){
            return stopStep * 2;
        }
        
        //IF RC[-9]="Спуск обсадной колонны",   RC[-1]*0.5
        if( operation == ActionChoices.DescentColumn ){
            return stopStep / 2;
        }
        
        //IF RC[-9]="Отбор керна",              ABS(RC[-1]-RC[-2])*2
        //IF RC[-9]="Проработка",               ABS(RC[-1]-RC[-2])*2
        //IF RC[-9]="Шаблонировка",             ABS(RC[-1]-RC[-2])*2
        return absDifference( stopStep, startStep ) * 2;
    }
    
    function addActionByIndex( uint startLH, uint endLH, uint startWeigth, uint endWeigth, uint action, uint idx ) public returns( uint ){
        require( uint(ActionChoices.TechnologySPO) >= action );
        require( idx < darOilHank.length );
        
        Action memory actionEvent;
        
        actionEvent.regTime = now;
        actionEvent.startLH = startLH;
        actionEvent.endLH = endLH;
        actionEvent.startWeigth = startWeigth;
        actionEvent.endWeigth = endWeigth;
        actionEvent.action = ActionChoices( action );
        
        
        dictActions[ idx ].push( actionEvent );
        
        if( actionEvent.action == ActionChoices.Reset ){
            darOilHank[ idx ].resetMTBF = 0;
        }else{
            uint labor = calculateActionValue( 
                action, 
                calculateStepLabour( darOilHank[ idx ].weigthVPS, darOilHank[ idx ].candleLength, startWeigth, startLH ), 
                calculateStepLabour( darOilHank[ idx ].weigthVPS, darOilHank[ idx ].candleLength, endWeigth, endLH ) 
            );
            
            darOilHank[ idx ].resetMTBF += labor;
            darOilHank[ idx ].lastActionMTBF += labor;
        }
        
        emit OilHankActionRegistered( darOilHank[ idx ].oilHankRegName, now, startLH, endLH, startWeigth, endWeigth, action );
        
        return dictActions[ idx ].length - 1;
    }
    
    
    function addAction( uint startLH, uint endLH, uint startWeigth, uint endWeigth, uint action, string oilHankRegName ) public returns( uint ){
        uint idx = indexOilHank[ sha256( bytes( oilHankRegName ) ) ]; 
        
        require( uint(ActionChoices.TechnologySPO) >= action );
        require( indexOilHank[ sha256( bytes( oilHankRegName ) ) ] > 0 );
        
        return addActionByIndex( startLH, endLH, startWeigth, endWeigth, action, idx );
    }
    
}

