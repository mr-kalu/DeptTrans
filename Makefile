COMPILER = g++
COMPILER_FLAGS = -std=c++17 -g -Wall -Werror -pedantic
COVERAGE_FLAGS = -fprofile-arcs -ftest-coverage
LINKER_FLAGS = -lgcov --coverage

TARGET = main                     # Entry point into the programme
C_FILES = $(wildcard *.cpp)             # All .cpp files in the directory
O_FILES = $(C_FILES:.cpp=.o)            # Convert .cpp to .o
H_FILES = $(wildcard *.h)               # All .h files in the directory

# Default target
all: $(TARGET)

# Link all object files into executable
$(TARGET): $(O_FILES)
	$(COMPILER) $(COMPILER_FLAGS) $(COVERAGE_FLAGS) -o $@ $^ $(LINKER_FLAGS)

# Compile each .cpp file into .o (depends on .h files)
%.o: %.cpp $(H_FILES)
	$(COMPILER) $(COMPILER_FLAGS) $(COVERAGE_FLAGS) -c $< -o $@

# Run with Valgrind
run: $(TARGET)
	valgrind --leak-check=full \
	         --show-leak-kinds=all \
	         --track-origins=yes \
			 --show-mismatched-frees=yes \
			 --keep-stacktraces=alloc-and-free \
	         --log-file=valgrind_log.txt \
	         ./$(TARGET)

# Generate coverage report
coverage: run
	@echo "Generating coverage report..."
	@lcov --capture --directory . --output-file coverage.info --quiet \
		--rc geninfo_unexecuted_blocks=1
	@lcov --remove coverage.info '/usr/*' --output-file coverage.info --quiet \
		--ignore-errors unused
	@genhtml coverage.info --output-directory coverage_report --quiet
	@echo "Coverage report generated in coverage_report/"

# Show coverage summary in terminal
coverage-summary: run
	@gcov $(C_FILES) > /dev/null
	@echo "\nCoverage Summary:"
	@for file in $(C_FILES); do \
		echo -n "$$file: "; \
		grep -oP 'Lines executed:\s*\K[\d.]+%' $$file.gcov || echo "0.00%"; \
	done

# Clean
clean:
	@rm -f $(O_FILES) $(TARGET) valgrind_log.txt *.gcda *.gcno *.gcov coverage.info
	@rm -rf coverage_report

.PHONY: all run debug clean coverage coverage-summary
