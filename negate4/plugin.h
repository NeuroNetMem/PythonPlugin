#ifndef __PYX_HAVE__negate4__plugin
#define __PYX_HAVE__negate4__plugin


#ifndef __PYX_HAVE_API__negate4__plugin

#ifndef __PYX_EXTERN_C
  #ifdef __cplusplus
    #define __PYX_EXTERN_C extern "C"
  #else
    #define __PYX_EXTERN_C extern
  #endif
#endif

__PYX_EXTERN_C DL_IMPORT(void) pluginStartup(void);
__PYX_EXTERN_C DL_IMPORT(int) getParamNum(void);
__PYX_EXTERN_C DL_IMPORT(void) getParamConfig(struct ParamConfig *);
__PYX_EXTERN_C DL_IMPORT(void) pluginFunction(float *, int, int);
__PYX_EXTERN_C DL_IMPORT(int) pluginisready(void);
__PYX_EXTERN_C DL_IMPORT(void) setIntParam(char *, int);
__PYX_EXTERN_C DL_IMPORT(void) setFloatParam(char *, int);

#endif /* !__PYX_HAVE_API__negate4__plugin */

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC initplugin(void);
#else
PyMODINIT_FUNC PyInit_plugin(void);
#endif

#endif /* !__PYX_HAVE__negate4__plugin */
