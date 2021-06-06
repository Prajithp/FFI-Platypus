#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"
#include "perl_math_int64.h"

void
ffi_pl_closure_add_data(SV *closure, ffi_pl_closure *closure_data)
{
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(closure);
  XPUSHs(sv_2mortal(newSViv(PTR2IV(closure_data))));
  XPUSHs(sv_2mortal(newSViv(PTR2IV(closure_data->type))));
  PUTBACK;
  call_pv("FFI::Platypus::Closure::add_data", G_DISCARD);
  FREETMPS;
  LEAVE;
}

ffi_pl_closure *
ffi_pl_closure_get_data(SV *closure, ffi_pl_type *type)
{
  dSP;
  int count;
  ffi_pl_closure *ret;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(closure);
  XPUSHs(sv_2mortal(newSViv(PTR2IV(type))));
  PUTBACK;
  count = call_pv("FFI::Platypus::Closure::get_data", G_SCALAR);
  SPAGAIN;

  if (count != 1)
    ret = NULL;
  else
    ret = INT2PTR(void*, POPi);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

void
ffi_pl_closure_call(ffi_cif *ffi_cif, void *result, void **arguments, void *user)
{
  ENTER_PERL_CONTEXT;
  dSP;

  ffi_pl_closure *closure = (ffi_pl_closure*) user;
  ffi_pl_type_extra_closure *extra = &closure->type->extra[0].closure;
  int flags = extra->flags;
  int i;
  int count;
  SV *sv,*ref;

  if(!(flags & G_NOARGS))
  {
    ENTER;
    SAVETMPS;
  }

  PUSHMARK(SP);

  if(!(flags & G_NOARGS))
  {
    for(i=0; i< ffi_cif->nargs; i++)
    {
      switch(extra->argument_types[i]->type_code)
      {
        case FFI_PL_TYPE_VOID:
          break;
        case FFI_PL_TYPE_SINT8:
          sv = sv_newmortal();
          sv_setiv(sv, *((int8_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_SINT16:
          sv = sv_newmortal();
          sv_setiv(sv, *((int16_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_SINT32:
          sv = sv_newmortal();
          sv_setiv(sv, *((int32_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_SINT64:
          sv = sv_newmortal();
          sv_seti64(sv, *((int64_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_UINT8:
          sv = sv_newmortal();
          sv_setuv(sv, *((uint8_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_UINT16:
          sv = sv_newmortal();
          sv_setuv(sv, *((uint16_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_UINT32:
          sv = sv_newmortal();
          sv_setuv(sv, *((uint32_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_UINT64:
          sv = sv_newmortal();
          sv_setu64(sv, *((uint64_t*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_FLOAT:
          sv = sv_newmortal();
          sv_setnv(sv, *((float*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_DOUBLE:
          sv = sv_newmortal();
          sv_setnv(sv, *((double*)arguments[i]));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_OPAQUE:
          sv = sv_newmortal();
          if( *((void**)arguments[i]) != NULL)
            sv_setiv(sv, PTR2IV( *((void**)arguments[i]) ));
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_STRING:
          sv = sv_newmortal();
          if( *((char**)arguments[i]) != NULL)
          {
            sv_setpv(sv, *((char**)arguments[i]));
          }
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_RECORD:
          sv = sv_newmortal();
          if( *((char**)arguments[i]) != NULL)
          {
            sv_setpvn(sv, *((char**)arguments[i]), extra->argument_types[i]->extra[0].record.size);
            if(extra->argument_types[i]->extra[0].record.class != NULL)
            {
              ref = newRV_inc(sv);
              sv_bless(ref, gv_stashpv(extra->argument_types[i]->extra[0].record.class, GV_ADD));
              SvREADONLY_on(sv);
              sv = ref;
            }
            else
            {
              SvREADONLY_on(sv);
            }
          }
          XPUSHs(sv);
          break;
        case FFI_PL_TYPE_RECORD_VALUE:
          sv = sv_newmortal();
          sv_setpvn(sv, (char*)arguments[i], extra->argument_types[i]->extra[0].record.size);
          ref = newRV_inc(sv);
          sv_bless(ref, gv_stashpv(extra->argument_types[i]->extra[0].record.class, GV_ADD));
          SvREADONLY_on(sv);
          XPUSHs(ref);
          break;
        default:
          warn("bad type");
          break;
      }
    }
    PUTBACK;
  }

  count = call_sv(closure->coderef, flags | G_EVAL);

  if(SvTRUE(ERRSV))
  {
#ifdef warn_sv
    warn_sv(ERRSV);
#else
    warn("%s", SvPV_nolen(ERRSV));
#endif
  }

  if(!(flags & G_DISCARD))
  {
    SPAGAIN;

    if(count != 1)
      sv = &PL_sv_undef;
    else
      sv = POPs;

    switch(extra->return_type->type_code)
    {
      case FFI_PL_TYPE_VOID:
        break;
      case FFI_PL_TYPE_UINT8:
#if defined FFI_PL_PROBE_BIGENDIAN
        ((uint8_t*)result)[3] = SvUV(sv);
#elif defined FFI_PL_PROBE_BIGENDIAN64
        ((uint8_t*)result)[7] = SvUV(sv);
#else
        *((uint8_t*)result) = SvUV(sv);
#endif
        break;
      case FFI_PL_TYPE_SINT8:
#if defined FFI_PL_PROBE_BIGENDIAN
        ((int8_t*)result)[3] = SvIV(sv);
#elif defined FFI_PL_PROBE_BIGENDIAN64
        ((int8_t*)result)[7] = SvIV(sv);
#else
        *((int8_t*)result) = SvIV(sv);
#endif
        break;
      case FFI_PL_TYPE_UINT16:
#if defined FFI_PL_PROBE_BIGENDIAN
        ((uint16_t*)result)[1] = SvUV(sv);
#elif defined FFI_PL_PROBE_BIGENDIAN64
        ((uint16_t*)result)[3] = SvUV(sv);
#else
        *((uint16_t*)result) = SvUV(sv);
#endif
        break;
      case FFI_PL_TYPE_SINT16:
#if defined FFI_PL_PROBE_BIGENDIAN
        ((int16_t*)result)[1] = SvIV(sv);
#elif defined FFI_PL_PROBE_BIGENDIAN64
        ((int16_t*)result)[3] = SvIV(sv);
#else
        *((int16_t*)result) = SvIV(sv);
#endif
        break;
      case FFI_PL_TYPE_UINT32:
#if defined FFI_PL_PROBE_BIGENDIAN64
        ((uint32_t*)result)[1] = SvUV(sv);
#else
        *((uint32_t*)result) = SvUV(sv);
#endif
        break;
      case FFI_PL_TYPE_SINT32:
#if defined FFI_PL_PROBE_BIGENDIAN64
        ((int32_t*)result)[1] = SvIV(sv);
#else
        *((int32_t*)result) = SvIV(sv);
#endif
        break;
      case FFI_PL_TYPE_UINT64:
        *((uint64_t*)result) = SvU64(sv);
        break;
      case FFI_PL_TYPE_SINT64:
        *((int64_t*)result) = SvI64(sv);
        break;
      case FFI_PL_TYPE_FLOAT:
        *((float*)result) = SvNV(sv);
        break;
      case FFI_PL_TYPE_DOUBLE:
        *((double*)result) = SvNV(sv);
        break;
      case FFI_PL_TYPE_OPAQUE:
        *((void**)result) = SvOK(sv) ? INT2PTR(void*, SvIV(sv)) : NULL;
        break;
      case FFI_PL_TYPE_RECORD_VALUE:
        if(sv_isobject(sv) && sv_derived_from(sv, extra->return_type->extra[0].record.class))
        {
          char *ptr;
          STRLEN len;
          ptr = SvPV(SvRV(sv), len);
          if(len > extra->return_type->extra[0].record.size)
            len = extra->return_type->extra[0].record.size;
          else if(len < extra->return_type->extra[0].record.size)
          {
            warn("Return record from closure is wrong size!");
            memset(result, 0, extra->return_type->extra[0].record.size);
          }
          memcpy(result, ptr, len);
          break;
        }
        warn("Return record from closure is wrong type!");
        memset(result, 0, extra->return_type->extra[0].record.size);
        break;
      default:
        warn("bad type");
        break;
    }

    PUTBACK;
  }

  if(!(flags & G_NOARGS))
  {
    FREETMPS;
    LEAVE;
  }
  LEAVE_PERL_CONTEXT;
}

