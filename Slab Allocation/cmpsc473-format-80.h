#define STRLEN   16

struct A {
	struct B *ptr_a; // 
	char string_b[STRLEN]; // Must have vowel or add to end
	char string_c[STRLEN]; // Capitalize Strings
	int num_d; // >0 or set to 0
	int num_e; // Any integer
	struct C *ptr_f; // 
	int (*op0)(struct A *objA);
	unsigned char *(*op1)(struct A *objA);
};
struct B {
	int num_a; // >0 or set to 0
	int num_b; // >0 or set to 0
	char string_c[STRLEN]; // Must have vowel or add to end
};
struct C {
	int num_a; // <0 or set to 0
	char string_b[STRLEN]; // Any string
	char string_c[STRLEN]; // Must have vowel or add to end
};
