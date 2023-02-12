typedef enum JSONType{
	STRING, // char*
	ARRAY, // JSONElement*
	BOOLEAN, // uint8,
	INTEGER, // uint64,
	OBJECT // JSONMapElement*
};

typedef struct JSONMapElement{
	char* key;
	JSONElement value;
};

typedef struct JSONElement {
	JSONType type;
	int length; // Not necessary this will be set
	void data;
};

/* { "abc" : [1, 2, "a"], "123": {"c": "b", "123": true}}
   JSONElement
   ├─ length: 2
   ├─ type: OBJECT
   └─ data: JSONMapElement*
      └─ JSONMapElement
         ├─ key: "abc"
         └─ value: JSONElement
                   ├─ length: 3
                   ├─ type: ARRAY
                   └─ data: JSONElement*
                            └─ JSONElement  
                               ├─ length: 0
                               ├─ type: INTEGER
                               └─ data: 1
                            └─ JSONElement  
                               ├─ length: 0
                               ├─ type: INTEGER
                               └─ data: 2
                            └─ JSONElement  
                               ├─ length: 1
                               ├─ type: STRING
                               └─ data: "a"
      └─ JSONMapElement
         ├─ key: "123"
         └─ value: JSONElement
                   ├─ length: 2
                   ├─ type: OBJECT
                   └─ data: JSONMapElement*
                            └─ JSONMapElement
                               ├─ key: "c"
                               └─ value: JSONElement
                                         ├─ length: 1
                                         ├─ type: STRING
                                         └─ data: "b"
                            └─ JSONMapElement
                               ├─ key: "123"
                               └─ value: JSONElement
                                         ├─ length: 2
                                         ├─ type: BOOLEAN
                                         └─ data: true 
*/
