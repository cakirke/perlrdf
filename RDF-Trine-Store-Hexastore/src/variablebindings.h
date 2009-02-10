#ifndef _VARIABLEBINDINGS_H
#define _VARIABLEBINDINGS_H

#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

#include "hexastore_types.h"
#include "nodemap.h"
#include "node.h"

typedef struct {
	int size;
	char** names;
	hx_node_id* nodes;
} hx_variablebindings;

typedef struct {
	int (*finished) ( void* iter );
	int (*current) ( void* iter, void* results );
	int (*next) ( void* iter );	
	int (*free) ( void* iter );
	int (*columns) ( void* iter );
	char** (*names) ( void* iter );
} hx_variablebindings_iter_vtable;

typedef struct {
	int size;
	char** names;
	hx_variablebindings_iter_vtable* vtable;
	void* ptr;
} hx_variablebindings_iter;

hx_variablebindings* hx_new_variablebindings ( int size, char** names, hx_node_id* nodes );
int hx_free_variablebindings ( hx_variablebindings* b, int free_names );

int hx_variablebindings_string ( hx_variablebindings* b, hx_nodemap* m, char** string );
void hx_variablebindings_debug ( hx_variablebindings* b, hx_nodemap* m );

int hx_variablebindings_size ( hx_variablebindings* b );
char* hx_variablebindings_name_for_binding ( hx_variablebindings* b, int column );
hx_node_id hx_variablebindings_node_for_binding ( hx_variablebindings* b, int column );

hx_variablebindings_iter* hx_variablebindings_new_iter ( hx_variablebindings_iter_vtable* vtable, void* ptr );
int hx_free_variablebindings_iter ( hx_variablebindings_iter* iter, int free_vtable );
int hx_variablebindings_iter_finished ( hx_variablebindings_iter* iter );
int hx_variablebindings_iter_current ( hx_variablebindings_iter* iter, hx_variablebindings** b );
int hx_variablebindings_iter_next ( hx_variablebindings_iter* iter );
int hx_variablebindings_iter_columns ( hx_variablebindings_iter* iter );
char** hx_variablebindings_iter_names ( hx_variablebindings_iter* iter );

#endif