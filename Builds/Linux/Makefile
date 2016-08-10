
CONDA_HOME := /usr/local/anaconda

LIBNAME := $(notdir $(CURDIR))
OBJDIR := $(OBJDIR)/$(LIBNAME)
TARGET := $(LIBNAME).so
OS := $(shell uname)

SRC_DIR := ${shell find ./ -type d -print}
VPATH := $(SOURCE_DIRS)

SRC := $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.cpp))
OBJ := $(addprefix $(OBJDIR)/,$(notdir $(SRC:.cpp=.o)))



#Extra macros and libraries needed by the plugin
#CXXFLAGS := $(CXXFLAGS) -D "PYTHON_HOME=$(CONDA_HOME)" -I $(CONDA_HOME)/include/python3.5m
CXXFLAGS := $(CXXFLAGS) -D "PYTHON_HOME=/usr/local" -I $(CONDA_HOME)/include/python3.5m
LDFLAGS := $(LDFLAGS) -lpython3.5m -L$(CONDA_HOME)/lib -Wl,-rpath=$(CONDA_HOME)/lib



BLDCMD := $(CXX) -shared -o $(OUTDIR)/$(TARGET) $(OBJ) $(LDFLAGS) $(RESOURCES) $(TARGET_ARCH)

VPATH = $(SRC_DIR)

.PHONY: objdir

$(OUTDIR)/$(TARGET): objdir $(OBJ)
	-@mkdir -p $(BINDIR)
	-@mkdir -p $(LIBDIR)
	-@mkdir -p $(OUTDIR)
	@echo "Building $(TARGET)"
	@$(BLDCMD)

$(OBJDIR)/%.o : %.cpp
	@echo "Compiling $<"
	@$(CXX) $(CXXFLAGS) -o "$@" -c "$<"
	
	
objdir:
	-@mkdir -p $(OBJDIR)

clean:
	@echo "Cleaning $(LIBNAME)"
	-@rm -rf $(OBJDIR)
	-@rm -f $(OUTDIR)/$(TARGET)

-include $(OBJ:%.o=%.d)
