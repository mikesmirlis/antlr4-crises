/*
Copyright (c) 2023 Michail Smyrlis
All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this source code and
associated documentation files (the "Code"), to use the Code for personal, educational, or research purposes.
Any commercial use of the Code, including but not limited to distribution in any form, modification,
or sale of the Code or any part thereof, is strictly prohibited without prior written permission
from the copyright owner.

THE CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
IN NO EVENT SHALL THE COPYRIGHT OWNER BE LIABLE FOR ANY CLAIM, DAMAGES,
OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE,
ARISING FROM, OUT OF, OR IN CONNECTION WITH THE CODE OR THE USE OR OTHER DEALINGS IN THE CODE.

*/

parser grammar CRISESParser;

options {
	tokenVocab = CRISESLexer;
}

root: (crises)+ EOF;

crises:
	tableSelection? tableCondition? filter? sortCondition? limitCondition? generateCondition;
//Generic identifier
columnWithIdentifier: IDENTIFIER DOT table_columns;
/*Table selection*/
tableSelection: FETCH table (COMMA table)*;
table: IDENTIFIER op = (COLON | DOT) reserved_tables;

/*Join table conditions*/
tableCondition:
	SUCH_THAT OPEN_PAREN joinTable (AND joinTable)* CLOSE_PAREN;
joinTable: fromTable DOT reserved_join_relations EQUAL toTable;
fromTable: IDENTIFIER;
toTable: IDENTIFIER;
/*Column typeFilter*/
filter: FILTER OPEN_PAREN filterCondition CLOSE_PAREN;
filterCondition: typeFilter (COMMA valueFilter)?;
valueFilter: valueConstraint (AND valueConstraint)*;
typeFilter: typeConstraint (AND typeConstraint)*;
/*Type Constraints*/
typeConstraint: enumTableColumnEquality;
enumTableColumnEquality:
	fromTable DOT type = (
		ASSET_TYPE
		| ASSESSMENT_TYPE
		| CATEGORY
	) EQUAL (
		assessment_type
		| data_category
		| asset_category
		| table_columns
	);

valueConstraint:
	valueConstraintWithSpecialCondition
	| valueConstraintWithCondition
	| tableColumnEquality;

valueConstraintWithSpecialCondition:
	specialConstraintInitialPart specialConstraint op = (
		LT
		| GT
		| EQUAL
		| NOT_EQUAL
		| LTE
		| GTE
		| LT_GT
		| IN
	) specialConstraintEndPart;

valueConstraintWithCondition:
	valueConstraingInitialPart op = (
		LT
		| GT
		| EQUAL
		| LTE
		| NOT_EQUAL
		| GTE
		| LT_GT
		| IN
	) (
		columnEquality
		| NUMERIC_LITERAL
		| INTEGER_LITERAL
		| HEX_INTEGER_LITERAL
		| functionCall
		| data_category
		| relation_constants
		| IDENTIFIER
		| columnWithIdentifier
	);

valueConstraingInitialPart: (
		columnWithIdentifier
		| IDENTIFIER DOT relation_constants
	);

tableColumnEquality:
	fromTable DOT fromTableColumn op = (EQUAL | NOT_EQUAL) toTable DOT toTableColumn;
fromTableColumn: table_columns;
toTableColumn: table_columns;

specialConstraintInitialPart: columnWithIdentifier;
specialConstraintEndPart: (
		columnEquality
		| NUMERIC_LITERAL
		| INTEGER_LITERAL
		| HEX_INTEGER_LITERAL
		| functionCall
		| data_category
	);
columnEquality: IDENTIFIER;
specialConstraint: '->>' (SINGLEQ_STRING_LITERAL | identifier);

sortCondition:
	ORDER BY OPEN_PAREN fromTable DOT columnName (
		COMMA columnName
	)* (op = (ASC | DESC))? CLOSE_PAREN;

columnName: reserved_keyword | table_columns;
limitCondition: LIMIT OPEN_PAREN INTEGER_LITERAL CLOSE_PAREN;
generateCondition:
	GENERATE assessmentResultCondition assetCondition securityPropertyCondition likelihoodCondition
		(
		valueCondition
	)?;

assessmentResultCondition:
	ASSESSMENT_RESULT assessmentResultIdentifier?;
assessmentResultIdentifier: IDENTIFIER COLON ASSESSMENT_RESULT;

assetCondition:
	ASSET assetIdentifier OPEN_PAREN assetGroup CLOSE_PAREN;
assetIdentifier: assetIdent DOT ASSET IN;
assetIdent: IDENTIFIER;
assetGroup: assetLocation (COMMA conditionFunction)?;
assetLocation:
	assetIdent
	| transitiveClosureFunction
	| mergeFunction;

conditionFunction:
	CONDITION OPEN_PAREN conditionArguments (
		AND conditionArguments
	)* CLOSE_PAREN;

conditionArguments:
	conditionOperator OPEN_PAREN condition CLOSE_PAREN;
conditionOperator: EXCLUDE | INCLUDE;
condition: conditionExpression (AND conditionExpression)*;
conditionExpression: relationCondition;
relationCondition:
	firstRelation COMMA reserved COMMA secondRelation;

firstRelation: identWithTable | identNoTable;
secondRelation: identWithTable | identNoTable;
identWithTable: identifier punctuation reserved;
punctuation: DOT | COLON;
identNoTable: identifier;
reserved:
	reserved_tables
	| reserved_join_relations
	| reserved_keyword;

mergeFunction:
	(assignIdentifier EQUAL)? MERGE OPEN_PAREN resultsIdentifier (
		COMMA resultsIdentifier
	)* CLOSE_PAREN;

assignIdentifier: IDENTIFIER;
resultsIdentifier: IDENTIFIER;

securityPropertyCondition:
	SECURITY_PROPERTY OPEN_PAREN columnWithIdentifier EQUAL securityPropertyFormula CLOSE_PAREN;
equalFormula: columnWithIdentifier;
securityPropertyFormula: equalFormula | matchFormula;
matchFormula:
	OPEN_BRACE security_property (COMMA security_property)* CLOSE_BRACE;
likelihoodCondition:
	LIKELIHOOD OPEN_PAREN columnWithIdentifier EQUAL likelihoodFormula CLOSE_PAREN;

likelihoodFormula:
	crisesFunction
	| mathematicFunction
	| statisticalFunction
	| aggregateFunction
	| noCondition;

noCondition: columnWithIdentifier;

mathematicFunction: mathematicExpression;
mathematicExpression:
	mathematicOperator OPEN_PAREN mathFirst COMMA mathSecond CLOSE_PAREN;
mathematicOperator: ADD | SUB | MUL | DIV | MOD;
mathFirst:
	crisesFunction
	| mathematicFunction
	| statisticalFunction
	| aggregateFunction
	| NUMERIC_LITERAL
	| INTEGER_LITERAL
	| HEX_INTEGER_LITERAL
	| IDENTIFIER;
mathSecond:
	crisesFunction
	| mathematicFunction
	| statisticalFunction
	| aggregateFunction
	| NUMERIC_LITERAL
	| INTEGER_LITERAL
	| HEX_INTEGER_LITERAL
	| IDENTIFIER;

statisticalFunction:
	statisticalOperator OPEN_PAREN columnWithIdentifier CLOSE_PAREN;
statisticalOperator: STDDEV | MEAN | MEDIAN | MODE | RANGE;

aggregateFunction:
	aggregateExpr
	| aggregateBetween
	| countFunction;
aggregateExpr:
	aggregateOperator OPEN_PAREN columnWithIdentifier CLOSE_PAREN;
aggregateOperator: MIN | MAX AVERAGE | SUM;

aggregateBetween:
	aggregateBetweenOperator OPEN_PAREN firstExpression COMMA secondExpression CLOSE_PAREN;
aggregateBetweenOperator: MAX_BETWEEN | MIN_BETWEEN;
firstExpression:
	crisesFunction
	| mathematicFunction
	| statisticalFunction
	| aggregateFunction
	| columnWithIdentifier
	| NUMERIC_LITERAL
	| INTEGER_LITERAL
	| HEX_INTEGER_LITERAL
	| IDENTIFIER;
secondExpression:
	crisesFunction
	| mathematicFunction
	| statisticalFunction
	| aggregateFunction
	| columnWithIdentifier
	| NUMERIC_LITERAL
	| INTEGER_LITERAL
	| HEX_INTEGER_LITERAL
	| IDENTIFIER;

countFunction: COUNT OPEN_PAREN countExpression CLOSE_PAREN;
countExpression:
	columnWithIdentifier op = (
		LT
		| GT
		| EQUAL
		| NOT_EQUAL
		| LTE
		| GTE
	) (number)		# countBasedOnComparison
	| IDENTIFIER	# singleIdentifier;
number: NUMERIC_LITERAL | INTEGER_LITERAL | HEX_INTEGER_LITERAL;

crisesFunction:
	propagationFunction
	| formulaFunction
	| specialConstraintFunction;
propagationFunction: PROPAGATE OPEN_PAREN formula CLOSE_PAREN;

valueCondition:
	VALUE OPEN_PAREN columnWithIdentifier EQUAL valueFormula CLOSE_PAREN;

valueFormula:
	crisesFunction
	| mathematicFunction
	| statisticalFunction
	| aggregateFunction
	| noCondition;

cardinality: STAR | PLUS | QMARK | repetition;
repetition:
	OPEN_BRACE num = (
		INTEGER_LITERAL
		| HEX_INTEGER_LITERAL
		| NUMERIC_LITERAL
	) (
		COMMA num = (
			INTEGER_LITERAL
			| HEX_INTEGER_LITERAL
			| NUMERIC_LITERAL
		)
	)? CLOSE_BRACE;

specialConstraintFunction:
	columnWithIdentifier formulaSpecialConstraint;

formulaSpecialConstraint:
	OPEN_PAREN varName CLOSE_PAREN
	| '->>' SINGLEQ_STRING_LITERAL;

formulaFunction: FORMULA OPEN_PAREN expr CLOSE_PAREN;

expr:
	expr op = (STAR | SLASH) expr				# mulDiv
	| expr op = (PLUS | MINUS) expr				# addSub
	| NUMERIC_LITERAL							# num
	| IDENTIFIER								# id
	| columnWithIdentifier						# simpleAssignment
	| OPEN_PAREN expr CLOSE_PAREN				# parens
	| columnWithIdentifier specialConstraint	# specialExpr;

varName: identifier;

formula:
	OPEN_PAREN? propagationTarget OPEN_PAREN? CLOSE_PAREN? op = (
		STAR
		| MINUS
		| PLUS
		| SLASH
		| CARET
	) CLOSE_PAREN? OPEN_PAREN? propagationTarget CLOSE_PAREN? (
		op = (STAR | MINUS | PLUS | SLASH | CARET) OPEN_PAREN? propagationTarget CLOSE_PAREN?
	)*;
propagationTarget:
	num = (
		INTEGER_LITERAL
		| HEX_INTEGER_LITERAL
		| NUMERIC_LITERAL
	)
	| propagationVariable
	| columnWithIdentifier;
propagationVariable: table_columns | propagation_keyword;

bool_expr:
	TRUE
	| FALSE
	| NOT bool_expr
	| bool_expr AND bool_expr
	| bool_expr OR bool_expr;

identifier:
	non_reserved_keyword
	| DOUBLEQ_STRING_LITERAL
	| IDENTIFIER
	| identifier DOT identifier
	| type_name
	| IDENTIFIER_UNICODE
	| relation_constants
	| relation_constants (cardinality)?
	| functionCall
	| reserved_keyword
	| table_columns;

type_name:
	BIGINT
	| BIT (OPEN_PAREN INTEGER_LITERAL CLOSE_PAREN)?
	| BOOLEAN
	| CHAR (OPEN_PAREN INTEGER_LITERAL CLOSE_PAREN)?
	| CHARACTER (OPEN_PAREN INTEGER_LITERAL CLOSE_PAREN)?
	| DATE
	| DECIMAL (
		OPEN_PAREN INTEGER_LITERAL COMMA INTEGER_LITERAL CLOSE_PAREN
	)?
	| DOUBLE PRECISION
	| INT
	| INTEGER
	| INTERVAL FIELDS? (INTEGER_LITERAL)?
	| NUMERIC (
		OPEN_PAREN INTEGER_LITERAL COMMA INTEGER_LITERAL CLOSE_PAREN
	)?
	| PATH
	| REAL
	| SMALLINT
	| TIME (OPEN_PAREN INTEGER_LITERAL CLOSE_PAREN)? (
		(WITH | WITHOUT) TIME ZONE
	)?
	| TIMESTAMP (OPEN_PAREN INTEGER_LITERAL CLOSE_PAREN)? (
		(WITH | WITHOUT) TIME ZONE
	)?
	| VARCHAR (OPEN_PAREN INTEGER_LITERAL CLOSE_PAREN)?;

relation_constants:
	INVOLVES
	| DISCOVERS
	| IMPLEMENTS
	| IMPLEMENTED_BY
	| PROVIDES_IMPLEMENTATION
	| INCLUDES
	| OUTPUT
	| INPUT
	| ADDRESSES
	| CONTAINS
	| TRANSMITS
	| SUPPORTS
	| DEPLOYS
	| CONTROLS
	| PRODUCES
	| DEPENDS
	| DEFINES
	| ALL;
functionName: EXISTS | NOT_EXISTS;
functionCall:
	functionName OPEN_PAREN startObject COMMA relation COMMA endObject CLOSE_PAREN
	| transitiveClosureFunction
	| timestampRange;

relation: relation_constants;

timestampRange:
	OPEN_PAREN timestampStart COMMA timestampEnd CLOSE_PAREN;
timestampStart:
	CURRENT_TIMESTAMP
	| CURRENT_TIMESTAMP op = (
		LT
		| GT
		| EQUAL
		| LTE
		| GTE
		| LT_GT
		| STAR
		| MINUS
		| PLUS
		| SLASH
		| CARET
	) (NUMERIC_LITERAL | INTEGER_LITERAL | HEX_INTEGER_LITERAL);
timestampEnd:
	CURRENT_TIMESTAMP
	| CURRENT_TIMESTAMP op = (
		LT
		| GT
		| EQUAL
		| LTE
		| GTE
		| LT_GT
		| STAR
		| MINUS
		| PLUS
		| SLASH
		| CARET
	) (NUMERIC_LITERAL | INTEGER_LITERAL | HEX_INTEGER_LITERAL);
startObject: (IDENTIFIER op = (COLON | DOT))? reserved_keyword
	| IDENTIFIER;
endObject: (IDENTIFIER op = (COLON | DOT))? reserved_keyword
	| IDENTIFIER;
transitiveClosureFunction: (transIdentifier EQUAL)? TRANSITIVE_CLOSURE OPEN_PAREN whereTransitive
		COMMA transitiveClosureCondition CLOSE_PAREN;
transIdentifier: IDENTIFIER;
whereTransitive: IDENTIFIER;
transitiveClosureCondition: relation_constants (cardinality)?;

non_reserved_keyword:
	| ABS
	| ACTION
	| ADA
	| ADD
	| ADMIN
	| AFTER
	| ASSERTION
	| ASSIGNMENT
	| AT
	| ATOMIC
	| ATTRIBUTE
	| ATTRIBUTES
	| AVG
	| BACKWARD
	| BEFORE
	| BEGIN
	| BERNOULLI
	| BETWEEN
	| BIGINT
	| BIT
	| BIT_LENGTH
	| BLOB
	| BOOLEAN
	| BREADTH
	| BY
	| CACHE
	| CALL
	| CALLED
	| CARDINALITY
	| CASCADE
	| CASCADED
	| CATALOG
	| CATALOG_NAME
	| CEIL
	| CEILING
	| CHAIN
	| CHAR
	| CHARACTER
	| CHARACTERISTICS
	| CHARACTERS
	| CHARACTER_LENGTH
	| CHARACTER_SET_CATALOG
	| CHARACTER_SET_NAME
	| CHARACTER_SET_SCHEMA
	| CHAR_LENGTH
	| CHECKPOINT
	| CLASS
	| CLASS_ORIGIN
	| CLOB
	| CLOSE
	| CLUSTER
	| COALESCE
	| COBOL
	| COLLATION_CATALOG
	| COLLATION_NAME
	| COLLATION_SCHEMA
	| COLLECT
	| COLUMN_NAME
	| COMMAND_FUNCTION
	| COMMAND_FUNCTION_CODE
	| COMMENT
	| COMMIT
	| COMMITTED
	| CONDITION
	| CONDITION_NUMBER
	| CONNECT
	| CONNECTION
	| CONNECTION_NAME
	| CONSTRAINTS
	| CONSTRAINT_CATALOG
	| CONSTRAINT_NAME
	| CONSTRAINT_SCHEMA
	| CONSTRUCTOR
	| CONTINUE
	| CONVERSION
	| CONVERT
	| COPY
	| CORR
	| CORRESPONDING
	| COUNT
	| COVAR_POP
	| COVAR_SAMP
	| CSV
	| CURRENT
	| DATABASE
	| DATE
	| DATETIME_INTERVAL_CODE
	| DATETIME_INTERVAL_PRECISION
	| DAY
	| DEALLOCATE
	| DEC
	| DECIMAL
	| DECLARE
	| DEFAULTS
	| DEFERRED
	| DEFINED
	| DEFINER
	| DEGREE
	| DELETE
	| DELIMITER
	| DELIMITERS
	| DENSE_RANK
	| DEPTH
	| DEREF
	| DERIVED
	| DESCRIBE
	| DESCRIPTOR
	| DETERMINISTIC
	| DIAGNOSTICS
	| DICTIONARY
	| DISCONNECT
	| DISPATCH
	| DOMAIN
	| DOUBLE
	| DYNAMIC
	| DYNAMIC_FUNCTION
	| DYNAMIC_FUNCTION_CODE
	| EACH
	| ELEMENT
	| ENCODING
	| ENCRYPTED
	| END
	| EQUALS
	| ESCAPE
	| EVERY
	| EXCEPTION
	| EXCLUDE
	| EXCLUDING
	| EXCLUSIVE
	| EXEC
	| EXECUTE
	| EXISTS
	| EXP
	| EXPLAIN
	| EXTENSION
	| EXTERNAL
	| EXTRACT
	| FILTER
	| FINAL
	| FIRST
	| FLOAT
	| FLOOR
	| FOLLOWING
	| FORCE
	| FORMAT
	| FORTRAN
	| FORWARD
	| FOUND
	| FREE
	| FUNCTION
	| FUSION
	| G_
	| GENERAL
	| GENERATED
	| GET
	| GLOBAL
	| GO
	| GOTO
	| GREATEST
	| GRANTED
	| GROUPING
	| HANDLER
	| HIERARCHY
	| HOLD
	| HOST
	| HOUR
	| IDENTITY
	| IGNORE
	| IMMEDIATE
	| IMMUTABLE
	| IMPLEMENTATION
	| IMPLICIT
	| INCLUDING
	| INCREMENT
	| INDEX
	| INDICATOR
	| INHERITS
	| INOUT
	| INPUT
	| INSENSITIVE
	| INSERT
	| INSTANCE
	| INSTANTIABLE
	| INSTEAD
	| INT
	| INTEGER
	| INTERSECTION
	| INTERVAL
	| INVOKER
	| ISOLATION
	| K_
	| KEY
	| KEY_MEMBER
	| KEY_TYPE
	| LANGUAGE
	| LARGE
	| LAST
	| LEAST
	| LEFT
	| LENGTH
	| LEVEL
	| LISTEN
	| LN
	| LOAD
	| LOCAL
	| LOCATION
	| LOCATOR
	| LOCK
	| LOCKED
	| LOWER
	| M_
	| MAP
	| MATCH
	| MATCHED
	| MAX
	| MAXVALUE
	| MEMBER
	| MERGE
	| MESSAGE_LENGTH
	| MESSAGE_OCTET_LENGTH
	| MESSAGE_TEXT
	| METHOD
	| MIN
	| MINUTE
	| MINVALUE
	| MOD
	| MODE
	| MODIFIES
	| MODULE
	| MONTH
	| MORE_
	| MOVE
	| MULTISET
	| MUMPS
	| NAME
	| NAMES
	| NATIONAL
	| NONE
	| NORMALIZE
	| NOTHING
	| NOTIFY
	| NULLABLE
	| NULLIF
	| NULLS
	| NUMBER
	| NUMERIC
	| OBJECT
	| OCTETS
	| OCTET_LENGTH
	| OF
	| OFF
	| OIDS
	| OLD
	| OPEN
	| OPERATOR
	| OPTION
	| OPTIONS
	| ORDERING
	| ORDINALITY
	| OTHERS
	| OUT
	| OUTPUT
	| OVER
	| OVERLAY
	| OVERRIDING
	| OWNER
	| PAD
	| PARAMETER
	| PARAMETER_MODE
	| PARAMETER_NAME
	| PARAMETER_ORDINAL_POSITION
	| PARAMETER_SPECIFIC_CATALOG
	| PARAMETER_SPECIFIC_NAME
	| PARAMETER_SPECIFIC_SCHEMA
	| PARTIAL
	| PARTITION
	| PASCAL
	| PASSWORD
	| PATH
	| PERCENTILE_CONT
	| PERCENTILE_DISC
	| PERCENT_RANK
	| PLAIN
	| PLI
	| POSITION
	| POWER
	| PRECEDING
	| PRECISION
	| PREPARE
	| PRESERVE
	| PRIOR
	| PRIVILEGES
	| PROCEDURAL
	| PROCEDURE
	| PUBLIC
	| QUOTE
	| RANGE
	| RANK
	| READ
	| READS
	| REAL
	| RECHECK
	| RECURSIVE
	| REF
	| REFERENCING
	| REFRESH
	| REGR_AVGX
	| REGR_AVGY
	| REGR_COUNT
	| REGR_INTERCEPT
	| REGR_SLOPE
	| REGR_SXX
	| REGR_SXY
	| REGR_SYY
	| REINDEX
	| RELATIVE
	| RELEASE
	| RENAME
	| REPEATABLE
	| REPLACE
	| RESET
	| RESTART
	| RESTRICT
	| RESULT
	| RETURN
	| RETURNED_CARDINALITY
	| RETURNED_LENGTH
	| RETURNED_OCTET_LENGTH
	| RETURNED_SQLSTATE
	| RETURNS
	| REVOKE
	| RIGHT
	| ROLE
	| ROLLBACK
	| ROLLUP
	| ROUTINE
	| ROUTINE_CATALOG
	| ROUTINE_NAME
	| ROUTINE_SCHEMA
	| ROW
	| ROWS
	| ROW_COUNT
	| ROW_NUMBER
	| RULE
	| SAVEPOINT
	| SCALE
	| SCHEMA
	| SCHEMA_NAME
	| SCOPE
	| SCOPE_CATALOG
	| SCOPE_NAME
	| SCOPE_SCHEMA
	| SCROLL
	| SEARCH
	| SECOND
	| SECTION
	| SECURITY
	| SELF
	| SENSITIVE
	| SEQUENCE
	| SEQUENCES
	| SERIALIZABLE
	| SERVER_NAME
	| SESSION
	| SET
	| SETOF
	| SETS
	| SHARE
	| SHOW
	| SIMPLE
	| SIZE
	| SMALLINT
	| SOME
	| SOURCE
	| SPACE
	| SPECIFIC
	| SPECIFICTYPE
	| SPECIFIC_NAME
	| SQL
	| SQLCODE
	| SQLERROR
	| SQLEXCEPTION
	| SQLSTATE
	| SQLWARNING
	| SQRT
	| STABLE
	| START
	| STATE
	| STATEMENT
	| STATIC
	| STATISTICS
	| STORAGE
	| STRICT
	| STRUCTURE
	| STYLE
	| SUBCLASS_ORIGIN
	| SUBMULTISET
	| SUBSTRING
	| SUM
	| SYSID
	| SYSTEM
	| SYSTEM_USER
	| TABLESPACE
	| TABLE_NAME
	| TEMP
	| TEMPLATE
	| TEMPORARY
	| TIES
	| TIME
	| TIMESTAMP
	| TIMEZONE_HOUR
	| TIMEZONE_MINUTE
	| TRANSACTION
	| TRANSACTIONS_COMMITTED
	| TRANSACTIONS_ROLLED_BACK
	| TRANSACTION_ACTIVE
	| TRANSFORM
	| TRANSFORMS
	| TRANSLATE
	| TRANSLATION
	| TREAT
	| TRIGGER
	| TRIGGER_CATALOG
	| TRIGGER_NAME
	| TRIGGER_SCHEMA
	| TRIM
	| TRUE
	| TRUNCATE
	| TRUSTED
	| TYPE
	| UESCAPE
	| UNBOUNDED
	| UNCOMMITTED
	| UNDER
	| UNENCRYPTED
	| UNKNOWN
	| UNLISTEN
	| UNNAMED
	| UNNEST
	| UNTIL
	| UPDATE
	| UPPER
	| USAGE
	| USER_DEFINED_TYPE_CATALOG
	| USER_DEFINED_TYPE_CODE
	| USER_DEFINED_TYPE_NAME
	| USER_DEFINED_TYPE_SCHEMA
	| VACUUM
	| VALID
	| VALIDATOR
	| VALUES
	| VARCHAR
	| VARYING
	| VAR_POP
	| VAR_SAMP
	| VIEW
	| VOLATILE
	| WHENEVER
	| WHITESPACE
	| WIDTH_BUCKET
	| WITHIN
	| WITHOUT
	| WORK
	| WRITE
	| YEAR
	| ZONE;
asset_category:
	DATA
	| SOFTWARE
	| HARDWARE
	| PHYSICAL_INFRASTRUCTURE
	| PROCESS
	| NETWORK
	| PERSON;
reserved_keyword: | relation_constants;
reserved_tables:
	| ASSET
	| ASSESSMENT_MODEL_EXECUTION
	| ASSESSMENT_CRITERION
	| ASSESSMENT_PROFILE
	| ASSESSMENT_RESULT
	| ASSET_GROUP
	| CTI_ASSESSMENT_RESULT
	| DATA
	| DATABASE
	| EXPOSED_SERVICE
	| HARDWARE
	| INTERFACE
	| INTERFACE_IMPLEMENTATION
	| MONITORING_ASSESSMENT_RESULT
	| NETWORK
	| NETWORK_INTERFACE
	| OPERATION
	| OPERATING_SYSTEM
	| OPENVASRESULT
	| ORGANISATION
	| PARAMETER
	| PERSON
	| PHYSICAL_INFRASTRUCTURE
	| PROCESS
	| PROJECT
	| RELATIONSHIP
	| SECURITY_CONTROL
	| SECURITY_PROPERTY
	| SOFTWARE
	| VIRTUAL_HARD_DISK
	| VULNERABILITY_ASSESSMENT_RESULT;
data_category:
	AUTHENTICATION_AUTHORIZATION
	| INTEGRITY
	| SECURITY
	| CONFIGURATION;
security_property: AVAILABILITY | CONFIDENTIALITY | INTEGRITY;

assessment_type:
	MONITOR
	| DYNAMIC_TESTING
	| VULNERABILITY_ASSESSMENT
	| CTI
	| INCIDENT_RESPONSE
	| ANY;
reserved_join_relations:
    STORES
    | CONTAINS
    | INCLUDES
    | COMMUNICATES
    | CONTROLS
    | CONTROLLED_BY
    | PROCESSES
    | PROCESSED_BY
    | DEPLOYS
    | DEPLOYED_BY
    | SUPPORTS
    | SUPPORTED_BY
    | TRANSMITS
    | INVOLVES
	| PRODUCES
	| PRODUCED_BY
	| PROTECTS
	| PROTECTED_BY
	| ADDRESSES
	| ADDRESSED_BY;
table_columns:
	| NORMALISED
	| INITIAL_DETECTION
	| ACTIVE_UNTIL
	| ASSET_ID
	| VALUE
	| SECURITY_PROPERTY_ID
	| SECURITYPROPERTY
	| ASSESSMENT_RESULT_ID
	| ID
	| ASSESSMENT_CRITERION_ID
	| ASSESSMENT_PROFILE_ID
	| ASSESSMENT_MODEL_EXECUTION_ID
	| ASSESSMENT_TYPE
	| ASSESSMENT_MODEL_ID
	| ASSESSMENT_MODEL_EXECUTION_ID
	| VARIABLE
	| LIKELIHOOD
	| CATEGORY
	| IFEVENTTIMESTAMP
	| THENEVENTTIMESTAMP
	| CVE_ID
	| TIMESTAMP
	| CVEID
	| CONFIDENCEVALUE;
propagation_keyword: DISTANCE;
