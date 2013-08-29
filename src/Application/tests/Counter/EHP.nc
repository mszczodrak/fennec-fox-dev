
#include <stdio.h>
#include <stdlib.h>

module EHP {
	provides interface SplitControl;

}

implementation {

FILE *fp;
char * line = NULL;
size_t len = 0;
ssize_t read;

command error_t SplitControl.start() {

	fp = fopen("/tmp/txt", "w");
		

	if (fp == NULL)
		return FAIL;

	while ((read = getline(&line, &len, fp)) != -1) {
//		printf("Retrieved line of length %zu :\n", read);
//		printf("%s", line);
	}

	return SUCCESS;
}

command error_t SplitControl.stop() {
	return SUCCESS;
}

}
