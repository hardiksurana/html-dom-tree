#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#define CAPACITY 100
#define TAG_LENGTH 100

/* structure declarations */

// declares structure for an element in the DOM tree
struct node {
	char *tag;
	struct attribute *attr;
	struct node *sibling;
	struct node *child;
	int level;
};

// declares structure for attributes of a DOM tree element
struct attribute {
	char *name;
	struct attribute *next_attr;
};

typedef struct node Node;
typedef struct attribute Attribute;

int closureWarningPrinted = 0;
int parseError = 0;

// root Node of the DOM tree
Node *head;

// top of stack variable
int tos;

// stack for correct linkages in DOM tree
Node *unclosed[CAPACITY];

// queue to display the DOM tree
Node *queue[CAPACITY];
int front_ptr, rear_ptr, size;

// level for display
int level;

/* sets the parseError variable according to the number */
void setParseError(int pe) {
	parseError = pe;
}

/* removes the first character from the parsed string */
void removeFirstChar(char *s) {
	if (*s == '\0')
		return;
	*s = *(s + 1);
	removeFirstChar(s + 1);
}

/* Queue Functions Begin */
/* checks if queue is full */
int is_queue_full() {
	return (size == CAPACITY);
}

/* checks if queue is empty */
int is_queue_empty() {
	return (size == 0 || front_ptr == -1);
}

/* adds a Node to the queue */
void enqueue(Node *item) {
	if (is_queue_full())
		return;

	if (front_ptr == -1) {
		front_ptr = 0;
	}

	size = size + 1;
	rear_ptr = (rear_ptr + 1) % CAPACITY;
	queue[rear_ptr] = (Node *)malloc(sizeof(Node));
	queue[rear_ptr] = item;
}

/* removes a Node from the queue */
Node *dequeue() {
	if (is_queue_empty())
		return (Node *) NULL;

	Node *item = queue[front_ptr];
	front_ptr = (front_ptr + 1) % CAPACITY;
	size = size - 1;
	if (front_ptr > rear_ptr) {
		front_ptr = -1;
		rear_ptr = -1;
	}
	return item;
}

/* gets the front element of queue */
Node *front() {
	if (is_queue_empty())
		return (Node *) NULL;
	return queue[front_ptr];
}

/* gets the rear element of queue */
Node *rear() {
	if (is_queue_empty())
		return (Node *) NULL;
	return queue[rear_ptr];
}
/* Queue Functions End */


/* displays DOM tree node attributes */
void display_attributes(Node *tag) {
	if (tag->attr != NULL) {
		printf("(");
		while (tag->attr->next_attr != NULL){
			printf("%s, ", tag->attr->name);
			tag->attr = tag->attr->next_attr;
		}
		printf("%s)", tag->attr->name);
	}
}

/* displays DOM tree elements in level order traversal */
void display() {
	printf("\n------------------------------ display called ------------------------------\n");
	Node *root = head;
	Node *front_tag;

	if(root != NULL) {
		enqueue(root);
		Node *temp_sibling = root->sibling;
		while(temp_sibling != NULL) {
			enqueue(temp_sibling);
		}

		while ((front_tag = front()) != NULL) {
			if(level == front_tag->level) {
				printf("\nL%d -> ", level);
			}

			Node *same_level_tags = front_tag;
			while(same_level_tags != NULL && same_level_tags->level == level) {
				same_level_tags = dequeue();

				Node *front_tag_child = same_level_tags->child;
				if (front_tag_child != NULL) {
					do {
						enqueue(front_tag_child);
						front_tag_child = front_tag_child->sibling;
					} while (front_tag_child != NULL);
				}

				printf("%s ", same_level_tags->tag);
				display_attributes(same_level_tags);
				printf(", ");
				same_level_tags = front();
			}

			level += 1;
		}
	} else {
		printf("No elements found in DOM.\n");
	}
}

/* Stack Functions Begin */
/* checks if the stack is full */
int is_stack_full() {
	return tos == CAPACITY;
}

/* checks if the stack is empty */
int is_stack_empty() {
	return tos == -1;
}

/* adds a new Node to the top of the stack */
int push(Node *new_tag) {
	if (is_stack_full())
		return -1;

	tos += 1;
	unclosed[tos] = (Node *)malloc(sizeof(Node));
	unclosed[tos] = new_tag;
}

/* removes a Node from the top of the stack */
int pop() {
	if (is_stack_empty())
		return -1;
	tos -= 1;
}

/* returns the topmost Node of the stack */
Node *peep() {
	if (is_stack_empty())
		return NULL;
	return unclosed[tos];
}
/* Stack Functions End */


/* first function to be called; initialises necessary variables and assigns memory */
void tree_init() {
	// initialise stack data
	tos = -1;

	// initialise level for display of DOM tree
	level = 0;

	// initialise queue
	front_ptr = -1;
	rear_ptr = -1;
	size = 0;

	// initialise root node of DOM tree
	head = (Node *)malloc(sizeof(Node));
	head->tag = (char *)malloc(sizeof(char) * TAG_LENGTH);
	head->attr = NULL;
	head->sibling = NULL;
	head->child = NULL;
	head->level = 0;
}

/* last function to be called which clears all memory and displays final parse status */
void tree_finish() {
	free(head);
	if (parseError) {
		printf("\n\n[ii]: Parse status: ERROR\n");
	} else {
		printf("\n\n[ii]: Parse status: SUCCESS!\n");
	}
}

/* creates a new DOM element in memory */
Node *tree_new_tag(char *tag_name) {
	Node *new_tag = (Node *) malloc(sizeof(Node));
	if (new_tag) {
		new_tag->tag = (char *)malloc(sizeof(char) * TAG_LENGTH);
		strcpy(new_tag->tag, tag_name);
		new_tag->child = NULL;
		new_tag->sibling = NULL;
		new_tag->attr = NULL;
	}
	push(new_tag);
	return new_tag;
}

/* adds a sibling to existing children of a DOM element */
Node *tree_add_sibling(Node *n, char *sibling_name) {
	if (n == NULL)
		return NULL;

	while (n->sibling)
		n = n->sibling;

	return (n->sibling = tree_new_tag(sibling_name));
}

/* adds a new DOM element to the tree */
Node *tree_add_child(char *child_name) {
	Node *top_tag = peep();

	// add first DOM element
	if (top_tag == NULL) {
		strcpy(head->tag, child_name);
		push(head);
	}
	
	// add first child to most nested element
	else if (top_tag->child) {
		Node *new_sibling = tree_add_sibling(top_tag->child, child_name);
		new_sibling->level = top_tag->child->level;
		return new_sibling;
	}

	// add sibling to existing child of most nested element
	else {
		top_tag->child = tree_new_tag(child_name);
		top_tag->child->level = top_tag->level + 1;
		return top_tag->child;
	}
}

/* connects attributes to an html element */
void tree_add_attribute(char *attr_name) {
	Node *tos = peep();
	Attribute **ptr = NULL;
	Attribute *attribute = NULL;
	
	if(tos != NULL) {
		// fill attribute structure
		attribute = (Attribute *)malloc(sizeof(Attribute));
		attribute->name = (char *)malloc(sizeof(char) * TAG_LENGTH);
		strcpy(attribute->name, attr_name);
		attribute->next_attr = NULL;
		
		// add to appropriate location in Node
		if(tos->attr == NULL) {
			tos->attr = attribute;
		} else {
			ptr = &(tos->attr);
			while ((*ptr)->next_attr != NULL)
				(*ptr) = (*ptr)->next_attr;
			(*ptr)->next_attr = attribute;
		}
	}
}