/*********************************************************************
 * Program: shasum.c
 * Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
 * Created: Sat May  5 20:54:30 EDT 2018
 * Updated: Mon May  7 14:04:01 EDT 2018
 * Purpose: Stata plugin for fast hashing
 * Note:    See stata.com/plugins for more on Stata plugins
 * Version: 0.1.4
 *********************************************************************/

/**
 * @file shasum.c
 * @author Mauricio Caceres Bravo
 * @date 07 May 2018
 * @brief Stata plugin
 *
 * This file should only ever be called from shasum.ado
 *
 * @see help shasum
 * @see http://www.stata.com/plugins for more on Stata plugins
 */

#include "shasum.h"

int main()
{
    return(0);
}

int WinMain()
{
    return(0);
}

STDLL stata_call(int argc, char *argv[])
{
    ST_retcode rc = 0;
    setlocale(LC_ALL, "");
    struct StataInfo *st_info = malloc(sizeof(*st_info));
    st_info->free = 0;

    if ( (rc = ssf_parse_info   (st_info, 0)) ) {
        goto exit;
    }

    if ( st_info->debug ) {
        printf("\tPlugin Step 2: Read varlist\n");
        sf_printf("\tPlugin Step 2: Read varlist\n");
    }

    if ( (rc = ssf_read_varlist (st_info, 0)) ) {
        goto exit;
    }

    if ( st_info->debug ) {
        printf("\tPlugin Step 3: Hash varlist\n");
        sf_printf("\tPlugin Step 3: Hash varlist\n");
    }

    if ( (rc = ssf_hash_varlist (st_info, 0)) ) {
        goto exit;
    }

exit:
    if ( st_info->debug ) {
        printf("\tPlugin Step 4: Cleanup\n");
        sf_printf("\tPlugin Step 4: Cleanup\n");
    }

    ssf_free (st_info);
    free (st_info);
    return (rc);
}

/**
 * @brief Parse variable info from Stata
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores in @st_info various info from Stata for the pugin run
 */
ST_retcode ssf_parse_info (struct StataInfo *st_info, int level)
{
    ST_retcode rc = 0;
    GT_size k, ilen, in1, in2, N, start;

    GT_size any_if,
            debug,
            /* benchmark, */
            concat,
            flist,
            rowbytes,
            kvars_targets,
            kvars_sources,
            kvars_num,
            kvars_str,
            lpath;

    // Check there are observations in the subset provided
    if ( (start = sf_anyobs_sel()) == 0 ) return (17001);

    // Get start and end position; number of variables
    in1 = SF_in1();
    in2 = SF_in2();
    N   = in2 - in1 + 1;
    if ( N < 1 ) return (17001);

    // Parse switches
    if ( (rc = sf_scalar_size("__shasum_debug",     &debug)     )) goto exit;
    // if ( (rc = sf_scalar_size("__shasum_benchmark", &benchmark) )) goto exit;
    if ( (rc = sf_scalar_size("__shasum_any_if",    &any_if)    )) goto exit;
    if ( (rc = sf_scalar_size("__shasum_concat",    &concat)    )) goto exit;
    if ( (rc = sf_scalar_size("__shasum_flist",     &flist)     )) goto exit;

    if ( (rc = sf_scalar_size("__shasum_kvars_sources",  &kvars_sources) )) goto exit;
    if ( (rc = sf_scalar_size("__shasum_kvars_targets",  &kvars_targets) )) goto exit;
    if ( (rc = sf_scalar_size("__shasum_kvars_num",      &kvars_num)     )) goto exit;
    if ( (rc = sf_scalar_size("__shasum_kvars_str",      &kvars_str)     )) goto exit;
    if ( (rc = sf_scalar_size("__shasum_lpath",          &lpath)         )) goto exit;

    if ( debug ) {
        printf("\tPlugin Step 1: Parsing stata info\n");
        sf_printf("\tPlugin Step 1: Parsing stata info\n");
    }

    st_info->inlens   = calloc(kvars_sources, sizeof st_info->inlens);
    st_info->outlens  = calloc(kvars_targets, sizeof st_info->outlens);
    st_info->shacodes = calloc(kvars_targets, sizeof st_info->shacodes);
    st_info->shalens  = calloc(kvars_targets, sizeof st_info->shalens);

    if ( st_info->inlens  == NULL ) {
        return (sf_oom_error("ssf_parse_info", "st_info->inlens "));
    }
    if ( st_info->outlens == NULL ) {
        return (sf_oom_error("ssf_parse_info", "st_info->outlens"));
    }
    if ( st_info->shacodes == NULL ) {
        return (sf_oom_error("ssf_parse_info", "st_info->shacodes"));
    }
    if ( st_info->shalens == NULL ) {
        return (sf_oom_error("ssf_parse_info", "st_info->shalens"));
    }

    if ( (rc = sf_get_vector_size ("__shasum_inlens",   st_info->inlens)   )) goto exit;
    if ( (rc = sf_get_vector_size ("__shasum_outlens",  st_info->outlens)  )) goto exit;
    if ( (rc = sf_get_vector_size ("__shasum_shacodes", st_info->shacodes) )) goto exit;

    for (k = 0; k < kvars_targets; k++) {
        if ( st_info->shacodes[k] == 1  ) {
            st_info->shalens[k] = MD5_DIGEST_LENGTH;
        }
        else if ( st_info->shacodes[k] == 2  ) {
            st_info->shalens[k] = SHA_DIGEST_LENGTH;
        }
        else if ( st_info->shacodes[k] == 3  ) {
            st_info->shalens[k] = SHA224_DIGEST_LENGTH;
        }
        else if ( st_info->shacodes[k] == 4  ) {
            st_info->shalens[k] = SHA256_DIGEST_LENGTH;
        }
        else if ( st_info->shacodes[k] == 5  ) {
            st_info->shalens[k] = SHA384_DIGEST_LENGTH;
        }
        else if ( st_info->shacodes[k] == 6 ) {
            st_info->shalens[k] = SHA512_DIGEST_LENGTH;
        }
    }

    st_info->free = 1;

    // Positions!
    // ----------

    st_info->positions = calloc(kvars_sources + 1, sizeof(st_info->positions));
    if ( st_info->positions == NULL ) {
        return (sf_oom_error("ssf_parse_info", "positions"));
    }
    st_info->free = 2;

    // The input variables are copied to a custom array. Technically it is a
    // Tcharacter array, but it is structured as follows:
    //
    //     | numeric | string7 | numeric | string32 |
    //     | 8 bytes | 7 bytes | 8 bytes | 32 bytes |
    //
    // string variables. The exception is if the variables are all
    // That is, we allocate enough bytes to hold all the numeric and
    //
    // numeric, in which case we simply use a numeric array. The
    // positions array stores the position of each entry. We have a
    // sepparate array that tells us the variable type and length of
    // each string (st_info->inlens). So we have, in the example above:
    //
    //     position[0] = 0
    //     position[1] = 8
    //     position[2] = 15
    //     position[3] = 23
    //
    //     st_info->inlens[0] = 0
    //     st_info->inlens[1] = 7
    //     st_info->inlens[2] = 0
    //     st_info->inlens[3] = 32
    //
    // 0 denotes a number, so we know to read 8 bytes. Then rowbytes
    // would be 55, the total number of bytes required to store roweach
    // of the variables.

    st_info->positions[0] = rowbytes = 0;
    for (k = 1; k < kvars_sources + 1; k++) {
        ilen = st_info->inlens[k - 1] * sizeof(char);
        if ( ilen > 0 ) {
            st_info->positions[k] = st_info->positions[k - 1] + (ilen + sizeof(char));
            rowbytes += (ilen + sizeof(char));
        }
        else {
            st_info->positions[k] = st_info->positions[k - 1] + sizeof(ST_double);
            rowbytes += sizeof(ST_double);
        }
    }
    rowbytes += sizeof(char);
    st_info->rowbytes = rowbytes;

    // Pass info to Stata
    // ------------------

    st_info->in1       = in1;
    st_info->in2       = in2;
    st_info->N         = N;
    st_info->Nread     = N;
    st_info->debug     = debug;
    // st_info->benchmark = benchmark;
    st_info->any_if    = any_if;
    st_info->concat    = concat;
    st_info->flist     = flist;

    st_info->kvars_sources = kvars_sources;
    st_info->kvars_targets = kvars_targets;
    st_info->kvars_num     = kvars_num;
    st_info->kvars_str     = kvars_str;
    st_info->lpath         = lpath;

exit:
    return(rc);
}

/**
 * @brief Read varlist to hash from stata
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores in @st_info->st_charx the input variables
 */
ST_retcode ssf_read_varlist (struct StataInfo *st_info, int level)
{
    ST_retcode rc = 0;
    ST_double z;
    GT_size i, k, sel, obs;

    GT_size rowbytes   = st_info->rowbytes;
    GT_size N          = st_info->N;
    GT_size in1        = st_info->in1;
    GT_size ksources   = st_info->kvars_sources;
    // GT_size kstr       = st_info->kvars_str;
    // GT_size knum       = st_info->kvars_num;
    GT_size *positions = st_info->positions;

    st_info->st_charx = calloc(N, rowbytes);
    if ( st_info->st_charx == NULL ) {
        return (sf_oom_error("ssf_read_varlist", "st_charx"));
    }
    st_info->free = 3;

    st_info->index = calloc(N, sizeof(st_info->index));
    if ( st_info->index == NULL ) {
        return (sf_oom_error("ssf_read_varlist", "index"));
    }

    if ( st_info->concat ) {
        st_info->rowix = calloc(N, sizeof(st_info->index));
        for (i = 0; i < N; i++) {
            st_info->rowix[i] = 0;
        }
    }
    else {
        st_info->rowix = malloc(sizeof(st_info->rowix));
    }

    st_info->free = 4;

    // Clean all the chunks
    for (i = 0; i < N; i++) {
        memset (st_info->st_charx + i * rowbytes, '\0', rowbytes);
    }

    // Loop through all the variables
    obs = 0;
    if ( st_info->concat ) {
        sel = 0;
        if ( st_info->any_if ) {
            for (i = 0; i < N; i++) {
                if ( SF_ifobs(i + in1) ) {
                    for (k = 0; k < ksources; k++) {
                        if ( st_info->inlens[k] > 0 ) {
                            if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) ) {
                                goto exit;
                            }
                            st_info->rowix[obs] += strlen(st_info->st_charx + sel);
                            sel += strlen(st_info->st_charx + sel);
                        }
                        else {
                            if ( (rc = SF_vdata(k + 1, i + in1, &z)) ) {
                                goto exit;
                            }
                            memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                            st_info->rowix[obs] += sizeof(ST_double);
                            sel += sizeof(ST_double);
                        }
                    }
                    sel += sizeof(char);
                    st_info->index[obs] = i;
                    ++obs;
                }
            }
        }
        else {
            for (i = 0; i < N; i++) {
                for (k = 0; k < ksources; k++) {
                    if ( st_info->inlens[k] > 0 ) {
                        if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) ) {
                            goto exit;
                        }
                        // printf("debug %lu: %s\n", i, st_info->st_charx + sel);
                        st_info->rowix[obs] += strlen(st_info->st_charx + sel);
                        sel += strlen(st_info->st_charx + sel);
                    }
                    else {
                        if ( (rc = SF_vdata(k + 1, i + in1, &z)) ) {
                            goto exit;
                        }
                        memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                        st_info->rowix[obs] += sizeof(ST_double);
                        sel += sizeof(ST_double);
                    }
                }
                sel += sizeof(char);
                st_info->index[obs] = i;
                ++obs;
            }
        }
    }
    else {
        if ( st_info->any_if ) {
            for (i = 0; i < N; i++) {
                if ( SF_ifobs(i + in1) ) {
                    for (k = 0; k < ksources; k++) {
                        sel = obs * rowbytes + positions[k];
                        if ( st_info->inlens[k] > 0 ) {
                            if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) ) {
                                goto exit;
                            }
                        }
                        else {
                            if ( (rc = SF_vdata(k + 1, i + in1, &z)) ) {
                                goto exit;
                            }
                            memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                        }
                    }
                    st_info->index[obs] = i;
                    ++obs;
                }
            }
        }
        else {
            for (i = 0; i < N; i++) {
                for (k = 0; k < ksources; k++) {
                    sel = obs * rowbytes + positions[k];
                    if ( st_info->inlens[k] > 0 ) {
                        if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) ) {
                            goto exit;
                        }
                    }
                    else {
                        if ( (rc = SF_vdata(k + 1, i + in1, &z)) ) {
                            goto exit;
                        }
                        memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                    }
                    // printf("debug %lu: %lu = %s\n", i, sel, st_info->st_charx + sel);
                }
                st_info->index[obs] = i;
                ++obs;
            }
        }
    }

    st_info->Nread = obs;

exit:
    return(rc);
}

/**
 * @brief Hash varlist to hash from stata
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores requested hashes in Stata output variables
 */
ST_retcode ssf_hash_varlist (struct StataInfo *st_info, int level)
{
    ST_retcode rc = 0;
    GT_size i, k, selrow, selix, selk, rowlen, nfail, nok;

    GT_size rowbytes   = st_info->rowbytes;
    GT_size Nread      = st_info->Nread;
    GT_size in1        = st_info->in1;
    GT_size ksources   = st_info->kvars_sources;
    GT_size ktargets   = st_info->kvars_targets;
    GT_size *shacodes  = st_info->shacodes;
    GT_size *shalens   = st_info->shalens;

    SHASUM_MAX (st_info->shalens, ktargets, shamax, i)

    MD5_CTX    ctx_md5;
    SHA_CTX    ctx_sha1;
    SHA256_CTX ctx_sha224;
    SHA256_CTX ctx_sha256;
    SHA512_CTX ctx_sha384;
    SHA512_CTX ctx_sha512;

    char * filename;
    char * filebuf = malloc(sizeof(char) * 512);
    memset (filebuf, '\0', 512 * sizeof(char));

    ssize_t filebytes;
    FILE *filehandle;

    unsigned char * iptr;
    unsigned char * hbuffer = malloc(sizeof(unsigned char) * shamax + sizeof(unsigned char));
    // memset(hbuffer, 0x0, sizeof(char) * shamax + sizeof(unsigned char));

    char * hptr;
    char * hashstr = malloc(sizeof(char) * (shamax * 2) + sizeof(char));
    // memset(hashstr, 0x0, sizeof(char) * (shamax * 2) + sizeof(char));

    if ( st_info->debug ) {
        printf("\t\tdebug 3 Nread:    "GT_size_cfmt"\n", Nread);
        printf("\t\tdebug 3 rowbytes: "GT_size_cfmt"\n", rowbytes);
        sf_printf("\t\tdebug 3 Nread:    "GT_size_cfmt"\n", Nread);
        sf_printf("\t\tdebug 3 rowbytes: "GT_size_cfmt"\n", rowbytes);
    }
    // printf("\t\tdebug 3 shamax: "GT_size_cfmt"\n", shamax);

    selrow = 0;
    if ( st_info->flist ) {

        SHASUM_MAX (st_info->rowix, Nread, strmax, i)
        filename = malloc(sizeof(char) * (strmax + st_info->lpath + 3));
        if ( filename == NULL ) {
            return (sf_oom_error("ssf_hash_varlist", "filename"));
        }
        else {
            memset (filename, '\0', sizeof(char) * (strmax + st_info->lpath + 3));
            if ( st_info->lpath ) {
                if ( (rc = SF_macro_use("_path", filename, (st_info->lpath + 1) * sizeof(char))) ) {
                    goto exit;
                }
            }
        }
        char * fileptr = filename + st_info->lpath;

        nfail = nok = 0;
        for (i = 0; i < Nread; i++) {
            rowlen = st_info->rowix[i];
            selix  = st_info->index[i];

            // memset(hbuffer, 0x0, sizeof(unsigned char) * shamax + sizeof(unsigned char));
            // memset(hashstr, 0x0, sizeof(char) * (shamax * 2) + sizeof(char));
            memset(hbuffer, '\0', sizeof(unsigned char) * shamax + sizeof(unsigned char));
            memset(hashstr, '\0', sizeof(char) * (shamax * 2) + sizeof(char));

            memcpy (fileptr, st_info->st_charx + selrow, rowlen);
            if ( access(filename, F_OK) == -1 ) {
                nfail++;
                continue;
            }
            else {
                nok++;
            }

            for (k = 0; k < ktargets; k++) {
                filehandle = fopen(filename, "rb");
                if ( shacodes[k] == 1  ) {
                    MD5_Init(&ctx_md5);
                    do {
                        filebytes = fread(filebuf, sizeof(char), 512, filehandle);
                        MD5_Update(&ctx_md5, filebuf, filebytes);
                    } while(filebytes > 0);
                    MD5_Final(hbuffer, &ctx_md5);
                }
                else if ( shacodes[k] == 2  ) {
                    SHA1_Init(&ctx_sha1);
                    do {
                        filebytes = fread(filebuf, sizeof(char), 512, filehandle);
                        SHA1_Update(&ctx_sha1, filebuf, filebytes);
                    } while(filebytes > 0);
                    SHA1_Final(hbuffer, &ctx_sha1);
                }
                else if ( shacodes[k] == 3  ) {
                    SHA224_Init(&ctx_sha224);
                    do {
                        filebytes = fread(filebuf, sizeof(char), 512, filehandle);
                        SHA224_Update(&ctx_sha224, filebuf, filebytes);
                    } while(filebytes > 0);
                    SHA224_Final(hbuffer, &ctx_sha224);
                }
                else if ( shacodes[k] == 4  ) {
                    SHA256_Init(&ctx_sha256);
                    do {
                        filebytes = fread(filebuf, sizeof(char), 512, filehandle);
                        SHA256_Update(&ctx_sha256, filebuf, filebytes);
                    } while(filebytes > 0);
                    SHA256_Final(hbuffer, &ctx_sha256);
                }
                else if ( shacodes[k] == 5  ) {
                    SHA384_Init(&ctx_sha384);
                    do {
                        filebytes = fread(filebuf, sizeof(char), 512, filehandle);
                        SHA384_Update(&ctx_sha384, filebuf, filebytes);
                    } while(filebytes > 0);
                    SHA384_Final(hbuffer, &ctx_sha384);
                }
                else if ( shacodes[k] == 6 ) {
                    SHA512_Init(&ctx_sha512);
                    do {
                        // filebytes = fread(filehandle, filebuf, 512);
                        filebytes = fread(filebuf, sizeof(char), 512, filehandle);
                        SHA512_Update(&ctx_sha512, filebuf, filebytes);
                    } while(filebytes > 0);
                    SHA512_Final(hbuffer, &ctx_sha512);
                }
                fclose (filehandle);

                selk = k + 1 + ksources;
                hptr = hashstr;

                for (iptr = hbuffer; iptr < hbuffer + shalens[k]; iptr++, hptr += 2) {
                    sprintf(hptr, "%02x", *iptr);
                }

                memset(hashstr + sizeof(char) * shalens[k] * 2, '\0', sizeof(char));
                // printf("debug %lu: %lu -> %lu = %s (%lu) -> %s\n",
                //        i, selrow, selix, st_info->st_charx + selrow, rowlen, hashstr);

                if ( (rc = SF_sstore(selk, selix + in1, hashstr)) ) {
                    goto exit;
                }
            }

            memset (fileptr, '\0', (strmax + 1) * sizeof(char));
            selrow += rowlen + st_info->concat;
        }

        sf_printf("("GT_size_cfmt" files hashed, "GT_size_cfmt" files not found)\n", nok, nfail);
        // printf("("GT_size_cfmt" files hashed, "GT_size_cfmt" files not found)\n", nok, nfail);
    }
    else {
        filename = malloc(sizeof(char));
        for (i = 0; i < Nread; i++) {
            rowlen = st_info->concat? st_info->rowix[i]: rowbytes;
            selix  = st_info->index[i];

            for (k = 0; k < ktargets; k++) {
                // hbuffer = malloc(sizeof(unsigned char) * shamax);
                memset(hbuffer, 0x0, sizeof(char) * shamax);
                memset(hashstr, 0x0, sizeof(char) * shamax * 2);

                if ( shacodes[k] == 1  ) {
                    MD5((unsigned char *) st_info->st_charx + selrow, rowlen, hbuffer);
                }
                else if ( shacodes[k] == 2  ) {
                    SHA1((unsigned char *) st_info->st_charx + selrow, rowlen, hbuffer);
                }
                else if ( shacodes[k] == 3  ) {
                    SHA224((unsigned char *) st_info->st_charx + selrow, rowlen, hbuffer);
                }
                else if ( shacodes[k] == 4  ) {
                    SHA256((unsigned char *) st_info->st_charx + selrow, rowlen, hbuffer);
                }
                else if ( shacodes[k] == 5  ) {
                    SHA384((unsigned char *) st_info->st_charx + selrow, rowlen, hbuffer);
                }
                else if ( shacodes[k] == 6 ) {
                    SHA512((unsigned char *) st_info->st_charx + selrow, rowlen, hbuffer);
                }

                selk = k + 1 + ksources;
                hptr = hashstr;

                for (iptr = hbuffer; iptr < hbuffer + shalens[k]; iptr++, hptr += 2) {
                    sprintf(hptr, "%02x", *iptr);
                }

                memset(hashstr + sizeof(char) * shalens[k] * 2, '\0', sizeof(char));
                // printf("debug %lu: %lu -> %lu = %s (%lu) -> %s\n",
                //        i, selrow, selix, st_info->st_charx + selrow, rowlen, hashstr);

                if ( (rc = SF_sstore(selk, selix + in1, hashstr)) ) {
                    goto exit;
                }
            }

            selrow += rowlen + st_info->concat;
        }
    }

exit:
    free (hbuffer);
    free (hashstr);
    free (filebuf);
    free (filename);
    return(rc);
}

/**
 * @brief Clean up st_info
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Frees memory allocated to st_info objects
 */
void ssf_free (struct StataInfo *st_info)
{
    if ( st_info->free >= 1 ) {
        free (st_info->inlens);
        free (st_info->outlens);
        free (st_info->shalens);
        free (st_info->shacodes);
    }
    if ( (st_info->free >= 2) ) {
        free (st_info->positions);
    }
    if ( (st_info->free >= 3) ) {
        // free (st_info->st_hash);
        free (st_info->st_charx);
    }
    if ( st_info->free >= 4 ) {
        if ( st_info->concat ) {
            free (st_info->rowix);
        }
        free (st_info->index);
    }
}
