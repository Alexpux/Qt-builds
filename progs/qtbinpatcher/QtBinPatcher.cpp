/*******************************************************************************

                   Copyright (C) 2012 Yuri V. Krugloff

   This program is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation, either version 3 of the License, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.

*******************************************************************************/

#undef OS_WINDOWS
#undef OS_LINUX

#if defined(_WIN32) || defined(__WIN32) || defined(__WIN32__) || \
    defined(__WINNT) || defined(__WINNT__)
    #define OS_WINDOWS
#elif defined(__linux) || defined(__linux__)
    #define OS_LINUX
#else
    #error "Unsupported OS."
#endif

#define _CRT_SECURE_NO_WARNINGS

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#if defined(OS_WINDOWS)
    #include <process.h>
    #include <io.h>
#elif defined(OS_LINUX)
    #include <sys/io.h>
    #include <glob.h>
    #include <sys/stat.h>
#endif
#ifdef _MSC_VER
    #include <direct.h>
#endif
#include <fcntl.h>

#include <string>
#include <vector>
#include <list>
#include <map>
#include <algorithm>

//------------------------------------------------------------------------------

using namespace std;

//------------------------------------------------------------------------------

typedef map<string, string> strmap;
typedef list<string> strlist;

//------------------------------------------------------------------------------
// Possible command line options.

const char* const OPT_HELP     = "--help";
const char* const OPT_VERBOSE  = "--verbose";
const char* const OPT_QT_DIR   = "--qt-dir";
const char* const OPT_NOBACKUP = "--nobackup";
const char* const OPT_FORCE    = "--force";

//------------------------------------------------------------------------------

const char* const QMAKE_NAME = "qmake"
#ifdef OS_WINDOWS
                               ".exe"
#endif
                               ;
const char* const BACKUP_SUFFIX = ".bak";

//------------------------------------------------------------------------------

#define QT_PATH_MAX_LEN 450

//------------------------------------------------------------------------------

// Flag for printing extended runtime information.
bool Verbose = false;

//------------------------------------------------------------------------------
// Native directory separator (OS-dependent).

inline char native_separator()
{
#if defined(OS_WINDOWS) && !defined(__MINGW32__)
    return '\\';
#else
    return '/';
#endif
}

//------------------------------------------------------------------------------
// Change directory separators to native (OS-dependent).

void to_native_separators(string* path)
{
    for (string::iterator I = path->begin(); I != path->end(); ++I)
        if (*I == '/' || *I == '\\')
            *I = native_separator();
}

//------------------------------------------------------------------------------
// Change directory separators to normal ('/') (OS-independent).

void to_normal_separators(string* path)
{
    for (string::iterator I = path->begin(); I != path->end(); ++I)
        if (*I == '\\')
            *I = '/';
}

//------------------------------------------------------------------------------
#ifdef OS_WINDOWS
// Case-insensitive comparision (only for case-independent file systems).

bool CaseInsensitiveComp(const char c1, const char c2)
{
    return tolower(c1) == tolower(c2);
}

#endif

//------------------------------------------------------------------------------
// String comparision. For OS Windows comparision is case-insensitive.

bool streq(const string& s1, const string& s2)
{
#ifdef OS_WINDOWS
    string _s1 = s1, _s2 = s2;
    transform(_s1.begin(), _s1.end(), _s1.begin(), ::tolower);
    transform(_s2.begin(), _s2.end(), _s2.begin(), ::tolower);
    return _s1 == _s2;
#else
    return s1 == s2;
#endif
}

//------------------------------------------------------------------------------
// Getting size of opened file.

long get_file_size(FILE* File)
{
#ifdef OS_WINDOWS
    return _filelength(_fileno(File));
#else
    struct stat Stat;
    if (fstat(fileno(File), &Stat) == 0)
        return Stat.st_size;
    return -1;
#endif
}

//------------------------------------------------------------------------------
// Truncation file to empty (zero size).

bool zero_file(FILE* File)
{
#ifdef OS_WINDOWS
    return _chsize(_fileno(File), 0) == 0;
#else
    return ftruncate(fileno(File), 0) == 0;
#endif
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Printing help information.

void help()
{
    printf(
        //.......|.........|.........|.........|.........|.........|.........|.........|
        "Usage: qtbinpatcher [options]\n"
        "Options:\n"
        "  --help       Show this help and exit.\n"
        "  --verbose    Print extended runtime information.\n"
        "  --qt-dir=dir Directory, where Qt or qmake is now located. If not specified,\n"
        "               the current directory is taken.\n"
        "  --nobackup   Don't create backup for files that'll be patch.\n"
        "  --force      Force patching (without old path actuality checking).\n"
        "\n"
        //.......|.........|.........|.........|.........|.........|.........|.........|
    );
}

//------------------------------------------------------------------------------
// Validating command line option.

bool validate_cmdline_opt(const char* Opt)
{
    static const char* const KnownCmdlineOpts[] = {
        OPT_HELP,
        OPT_VERBOSE,
        OPT_QT_DIR,
        OPT_NOBACKUP,
        OPT_FORCE
    };

    for (size_t n = 0; n < sizeof(KnownCmdlineOpts)/sizeof(KnownCmdlineOpts[0]); ++n)
        if (strcmp(Opt, KnownCmdlineOpts[n]) == 0)
            return true;

    return false;
}

//------------------------------------------------------------------------------
/* Parser for command line arguments.
   Return true, if parsing successful and false otherwise. */

bool parse_cmdline_args(int argc,
                        char* argv[],
                        strmap* pCmdlineArgs)
{
    for (int i = 1; i < argc; ++i) {
        string Opt = argv[i];
        string::size_type pos = Opt.find('=');
        string OptName = Opt.substr(0, pos);
        (*pCmdlineArgs)[OptName] = (pos != string::npos) ? Opt.substr(pos + 1) : "";
        if (!validate_cmdline_opt(OptName.c_str())) {
            fprintf(stderr, "Unknown command line option: %s\n\n", OptName.c_str());
            return false;
        }
    }

    Verbose = pCmdlineArgs->count(OPT_VERBOSE) > 0;

    if (Verbose) {
        printf("Parsed command line arguments:\n");
        for (strmap::iterator I = pCmdlineArgs->begin(); I != pCmdlineArgs->end(); ++I) {
            printf("%s", I->first.c_str());
            if (!I->second.empty())
                printf(" = %s", I->second.c_str());
            putchar('\n');
        }
        putchar('\n');
    }

    return true;
}

//------------------------------------------------------------------------------
// Return true if file with name FileName is exists and false otherwise.

bool is_file_exists(const char* const FileName)
{
#if defined(OS_WINDOWS)
    _finddata_t FindData;
    intptr_t FindHandle = _findfirst(FileName, &FindData);
    if (FindHandle != -1) {
        _findclose(FindHandle);
        return true;
    }
#elif defined(OS_LINUX)
    glob_t GlobData;
    if (glob(FileName, 0, NULL, &GlobData) == 0) {
        globfree(&GlobData);
        return true;
    }
#else
    #error "Unsupported OS."
#endif
    return false;
}


//------------------------------------------------------------------------------
/* Generate path to new Qt directory.
   Returned value don't have direcrory separators at the end
   and all separators in path is native. */

string get_new_qt_path(const strmap* pCmdlineOpts)
{
    string Result;
    if (pCmdlineOpts->count(OPT_QT_DIR) > 0) {
        Result = pCmdlineOpts->at(OPT_QT_DIR);
    }
    else {
        #ifdef _MSC_VER
            #define GETCWD _getcwd
        #else
            #define GETCWD getcwd
        #endif
        char* cwd = GETCWD(NULL, 1024);
        if (cwd != NULL) {
            Result = cwd;
            free(cwd);
        }
        else {
            fprintf(stderr, "Error of getting current directory!\n");
        }
    }
    to_native_separators(&Result);

    int i = static_cast<int>(Result.size()) - 1;
    while (i >= 0 && Result[i] == native_separator()) {
        Result.erase(i);
        --i;
    }

    if (is_file_exists((Result + native_separator() + QMAKE_NAME).c_str())) {
        // One level up.
        string::size_type pos = Result.find_last_of(native_separator());
        if (pos != string::npos && pos < Result.length() - 1)
            Result.resize(pos);
    }

    if (Verbose)
        printf("Path to new Qt directory: %s\n\n", Result.c_str());

    return Result;
}

//------------------------------------------------------------------------------
// Start qmake and get output into buffer.

bool get_qmake_output(const string& QtPath,
                      char* Buffer,
                      int BufferSize)
{
    bool Result = false;
    string QMakeStart = "\"\"" + QtPath + "/bin/" + QMAKE_NAME + "\" -query\"";

    if (Verbose)
        printf("qmake command line: %s\n\n", QMakeStart.c_str());

    int fdPipe[2];
    if (
#ifdef OS_WINDOWS
        _pipe(fdPipe, BufferSize, O_BINARY) == 0
#else
        pipe(fdPipe) == 0
#endif
        ) {
        int old_stdout = dup(fileno(stdout));
        if (old_stdout != -1) {
            if (dup2(fdPipe[1], fileno(stdout))
#ifdef OS_WINDOWS
                    == 0
#else
                    != -1
#endif
                    ) {
                int ExecCode = system(QMakeStart.c_str());
                if (ExecCode == 0) {
                    if (dup2(old_stdout, fileno(stdout))
#ifdef OS_WINDOWS
                    != 0
#else
                    == -1
#endif
                    ) {
                        fprintf(stderr, "Error restore stdout handle!\n\n");
                    }

                    int Readed = read(fdPipe[0], Buffer, BufferSize - 1);
                    Buffer[Readed] = '\0';
                    Result = true;
                }
                else {
                    fprintf(stderr, "Error running qmake.exe!\n\n");
                }
            }
            else {
                fprintf(stderr, "Error replace stdout handle!\n\n");
            }
            close(old_stdout);
        }
        else {
            fprintf(stderr, "Error duplicate stdout handle!\n");
        }

        close(fdPipe[1]);
        close(fdPipe[0]);
    }
    else {
        fprintf(stderr, "Error creating pipe for qmake output!\n\n");
    }

    return Result;
}

//------------------------------------------------------------------------------
/* Parser for qmake output.
   Return true, if parsing successful and false otherwise. */

bool parse_qmake_output(char* Output,
                        strmap* pQmakeValues)
{
    const char *const Delimiters = " \r\n";
    char* s = strtok(Output, Delimiters);
    while (s != NULL) {
        string str = s;
        string::size_type i = str.find(':');
        if (i != string::npos) {
            (*pQmakeValues)[str.substr(0, i)] = str.substr(i + 1);
        }
        else {
            fprintf(stderr, "Error parsing qmake output string:\n\t\"%s\"", s);
            return false;
        }
        s = strtok(NULL, Delimiters);
    }

    if (Verbose) {
        printf("Parsed Qt variables:\n");
        for (strmap::iterator I = pQmakeValues->begin(); I != pQmakeValues->end(); ++I)
            printf("%s = %s\n", I->first.c_str(), I->second.c_str());
        putchar('\n');
    }

    return true;
}

//------------------------------------------------------------------------------
// Replace char in string to new substring.

void replace(string* pS, char before, const char* after)
{
    size_t len = strlen(after);
    size_t pos = pS->find(before);
    while (pos != string::npos) {
        pS->replace(pos, 1, after);
        pos = pS->find(before, pos + len);
    }
}

//------------------------------------------------------------------------------
// Construct patch values for text files.

void get_text_patch_values(string OldQtPath,
                           string NewQtPath,
                           strmap* pPatchValues)
{
    to_normal_separators(&OldQtPath);
    to_normal_separators(&NewQtPath);

    (*pPatchValues)[OldQtPath] = NewQtPath;
    string S1;
    S1 = OldQtPath;
    replace(S1.begin(), S1.end(), '/', '\\');
    (*pPatchValues)[S1] = NewQtPath;
#ifdef OS_WINDOWS
    string NewQtPathDS = NewQtPath;
    replace(&NewQtPathDS, '/', "\\\\");
    S1 = OldQtPath;
    replace(&S1, '/', "\\\\");
    (*pPatchValues)[S1] = NewQtPathDS;
#endif

    if (Verbose) {
        printf("\nPatch values for text files:\n");
        for (strmap::const_iterator I = pPatchValues->begin(); I != pPatchValues->end(); ++I)
            printf("%s\n  -> %s\n", I->first.c_str(), I->second.c_str());
        putchar('\n');
    }
}

//------------------------------------------------------------------------------
// Construct patch values for binary files.

void get_bin_patch_values(strmap& QmakeValues,
                          const string& NewQtPath,
                          strmap* pPatchValues)
{
    struct TParam {
        const char* const Name;
        const char* const Prefix;
        const char* const Dir;
    };

    static const TParam Params[] = {
        { "QT_INSTALL_PREFIX",       "qt_prfxpath=", NULL           },
        { "QT_INSTALL_ARCHDATA",     "qt_adatpath=", NULL           },
        { "QT_INSTALL_DOCS",         "qt_docspath=", "doc"          },
        { "QT_INSTALL_HEADERS",      "qt_hdrspath=", "include"      },
        { "QT_INSTALL_LIBS",         "qt_libspath=", "lib"          },
        { "QT_INSTALL_LIBEXECS",     "qt_lbexpath=", "libexec"      },
        { "QT_INSTALL_BINS",         "qt_binspath=", "bin"          },
        { "QT_INSTALL_PLUGINS",      "qt_plugpath=", "plugins"      },
        { "QT_INSTALL_IMPORTS",      "qt_impspath=", "imports"      },
        { "QT_INSTALL_QML",          "qt_qml2path=", "qml"          },
        { "QT_INSTALL_DATA",         "qt_datapath=", NULL           },
        { "QT_INSTALL_TRANSLATIONS", "qt_trnspath=", "translations" },
        { "QT_INSTALL_EXAMPLES",     "qt_xmplpath=", "examples"     },
        { "QT_INSTALL_DEMOS",        "qt_demopath=", "demos"        },
        { "QT_INSTALL_TESTS",        "qt_tstspath=", "tests"        },
        { "QT_HOST_PREFIX",          "qt_hpfxpath=", NULL           },
        { "QT_HOST_BINS",            "qt_hbinpath=", "bin"          },
        { "QT_HOST_DATA",            "qt_hdatpath=", NULL           },
        { "QT_HOST_LIBS",            "qt_hlibpath=", "lib"          }
    };

    for (size_t i = 0; i < sizeof(Params)/sizeof(Params[0]); ++i)
    {
        const TParam& Param = Params[i];
        string OldValue = QmakeValues[Param.Name];
        if (!OldValue.empty()) {
            OldValue.insert(0, Param.Prefix);
            string NewValue = Param.Prefix;
            NewValue.append(NewQtPath);
            if (Param.Dir != NULL) {
                NewValue += native_separator();
                NewValue += Param.Dir;
            }
            (*pPatchValues)[OldValue] = NewValue;
        }
        else {
            if (Verbose)
                printf("Variable %s not found in qmake output.\n", Param.Name);
        }
    }

    if (Verbose) {
        printf("\nPatch values for binary files:\n");
        for (strmap::const_iterator I = pPatchValues->begin(); I != pPatchValues->end(); ++I)
            printf("%s\n  -> %s\n", I->first.c_str(), I->second.c_str());
        putchar('\n');
    }
}

//------------------------------------------------------------------------------
// Copy file "From" to file "To".

bool copy_file(const char* From,
               const char* To)
{
    bool Result = true;
    FILE* src = fopen(From, "rb");
    if (src != NULL) {
        FILE* dst = fopen(To, "wb");
        if (dst != NULL) {
            char Buffer[1024*16];
            size_t size;
            while (!feof(src)) {
                size = fread(Buffer, 1, sizeof(Buffer), src);
                if (fwrite(Buffer, 1, size, dst) != size) {
                    fprintf(stderr, "Error writing to file %s!\n", To);
                    Result = false;
                    break;
                }
            }
            fclose(dst);
        }
        else {
            fprintf(stderr, "Error opening file for writing: %s!\n", To);
            Result = false;
        }
        fclose(src);
    }
    else {
        fprintf(stderr, "Error opening file for reading: %s!\n", From);
        Result = false;
    }
    return Result;
}

//------------------------------------------------------------------------------
// Backup one file.

bool backup_file(const string& FileName)
{
    if (Verbose)
        printf("Backing up file %s...", FileName.c_str());

    string BackupFileName = FileName + BACKUP_SUFFIX;
    bool Result = copy_file(FileName.c_str(), BackupFileName.c_str());

    if (Verbose)
        printf(Result ? " OK\n" : " Failed\n");

    return Result;
}

//------------------------------------------------------------------------------
/* Backup files. If one of the files can't be backup, interrupt process and
   return false. */

bool backup_files(const strlist& FilesList)
{
    for (strlist::const_iterator I = FilesList.begin(); I != FilesList.end(); ++I)
        if (!backup_file(*I))
            return false;

    if (Verbose)
        putchar('\n');

    return true;
}

//------------------------------------------------------------------------------
// Restore one file.

bool restore_file(const string& FileName)
{
    if (Verbose)
        printf("Restoring from backup file %s...", FileName.c_str());

    remove(FileName.c_str());
    bool Result = rename((FileName + BACKUP_SUFFIX).c_str(), FileName.c_str()) == 0;

    if (Verbose)
        printf(Result ? " OK\n" : " Failed\n");

    return Result;
}

//------------------------------------------------------------------------------
/* Restore files. If one or more files can't be restored, return false.
   (Restore process do not interrupted.) */

bool restore_files(const strlist& FilesList)
{
    bool Result = true;
    for (strlist::const_iterator I = FilesList.begin(); I != FilesList.end(); ++ I)
        if (!restore_file(*I))
            Result = false;

    if (Verbose)
        putchar('\n');

    return Result;
}

//------------------------------------------------------------------------------
/* Find files satisfied to mask Mask in directory Dir.
   Dir must have final directory separator! */

void find_files(const string Dir,
                const string Mask,
                strlist* pFilesList)
{
#if defined(OS_WINDOWS)
    _finddata_t FindData;
    intptr_t FindHandle = _findfirst((Dir + Mask).c_str(), &FindData);
    if (FindHandle != -1) {
        do {
            if ((FindData.attrib & _A_SUBDIR) == 0)
                pFilesList->push_back(Dir + FindData.name);
        } while (_findnext(FindHandle, &FindData) == 0);
        _findclose(FindHandle);
    }
#elif defined(OS_LINUX)
    glob_t GlobData;
    if (glob((Dir + Mask).c_str(), GLOB_MARK, NULL, &GlobData) == 0) {
        for (size_t i = 0; i < GlobData.gl_pathc; ++i) {
            const char* path = GlobData.gl_pathv[i];
            if (path[strlen(path) -1] !=  '/')
                pFilesList->push_back(path);
        }
        globfree(&GlobData);
    }
#else
    #error "Unsupported OS."
#endif
}

//------------------------------------------------------------------------------
/* Finding files in directory Dir and all their subdirectories, satisfied to
   mask Mask. Dir must have final directory separator! */

void find_files_recursive(const string Dir, const string Mask, strlist* pFilesList)
{
#if defined (OS_WINDOWS)
    _finddata_t FindData;
    intptr_t FindHandle = _findfirst((Dir + "*").c_str(), &FindData);
    if (FindHandle != -1) {
        do {
            if ((FindData.attrib & _A_SUBDIR) != 0 &&
                strcmp(FindData.name, ".")  != 0   &&
                strcmp(FindData.name, "..") != 0)
            {
                find_files_recursive(Dir + FindData.name + "/", Mask, pFilesList);
            }
        } while (_findnext(FindHandle, &FindData) == 0);
        _findclose(FindHandle);
    }

    find_files(Dir, Mask, pFilesList);
#elif defined (OS_LINUX)
    glob_t GlobData;
    if (glob((Dir + Mask).c_str(), GLOB_MARK, NULL, &GlobData) == 0) {
        for (size_t i = 0; i < GlobData.gl_pathc; ++i) {
            const char* path = GlobData.gl_pathv[i];
            if (path[strlen(path) - 1] != '/')
                pFilesList->push_back(path);
            else
                find_files_recursive(path, Mask, pFilesList);
        }
    }
#endif
}

//------------------------------------------------------------------------------
// Create list of text files to patch.

void get_txt_files_for_patch(const string& NewQtPath,
                             const char QtVersion,
                             strlist* pFilesList)
{
    struct TElement {
        const char* const Dir;
        const char* const Name;
        const bool        Recursive;
    };

    // Files for patching in Qt4.
    static const TElement Elements4[] = {
        { "/lib/",             "*.prl",              false },
        { "/demos/shared/",    "libdemo_shared.prl", false },
#ifdef OS_WINDOWS
        { "/mkspecs/default/", "qmake.conf",         false },
        { "/",                 ".qmake.cache",       false }
#elif defined(OS_LINUX)
        { "/lib/",             "*.la",               false },
        { "/lib/pkgconfig/",   "*.pc",               false },
        { "/mkspecs/",         "qconfig.pri",        false }
#endif
    };
    // Files for patching in Qt5.
    static const TElement Elements5[] = {
        { "/",                             "*.la",                        true  },
        { "/",                             "*.prl",                       true  },
        { "/",                             "*.pc",                        true  },
        { "/",                             "*.pri",                       true  },
        { "/lib/cmake/Qt5LinguistTools/", "Qt5LinguistToolsConfig.cmake", false },
        { "/mkspecs/default-host/",       "qmake.conf",                   false },
#ifdef OS_WINDOWS
        { "/mkspecs/default/",            "qmake.conf",                   false },
        { "/",                            ".qmake.cache",                 false },
        { "/lib/",                        "prl.txt",                      false }
#endif
    };

    const TElement* Elements;
    size_t Count;
    switch (QtVersion) {
        case '4' :
            Elements = Elements4;
            Count = sizeof(Elements4)/sizeof(Elements4[0]);
            break;
        case '5' :
            Elements = Elements5;
            Count = sizeof(Elements5)/sizeof(Elements5[0]);
            break;
        default :
            abort();
    }
    for (size_t i = 0; i < Count; ++i) {
        if (Elements[i].Recursive)
            find_files_recursive(NewQtPath + Elements[i].Dir, Elements[i].Name, pFilesList);
        else
            find_files(NewQtPath + Elements[i].Dir, Elements[i].Name, pFilesList);
    }
}

//------------------------------------------------------------------------------
// Create list of binary files to patch.

void get_bin_files_for_patch(const string& NewQtPath,
                             const char QtVersion,
                             strlist* pFilesList)
{
    struct TElement {
        const char* const Dir;
        const char* const Name;
    };

    // Files for patching in Qt4.
    static const TElement Elements4[] = {
#ifdef OS_WINDOWS
        { "/bin/", "qmake.exe"    },
        { "/bin/", "lrelease.exe" },
        { "/bin/", "QtCore*.dll"  },
        { "/lib/", "QtCore*.dll"  }
#elif defined(OS_LINUX)
        { "/bin/", "qmake"        },
        { "/bin/", "lrelease"     },
        { "/lib/", "libQtCore.so" }
#endif
    };
    // Files for patching in Qt5.
    static const TElement Elements5[] = {
#ifdef OS_WINDOWS
        { "/bin/", "qmake.exe"    },
        { "/bin/", "lrelease.exe" },
        { "/lib/", "qdoc.exe"     },
        { "/bin/", "Qt5Core*.dll" },
        { "/lib/", "Qt5Core*.dll" }
#elif defined(OS_LINUX)
        { "/bin/", "qmake"        },
        { "/bin/", "lrelease"     },
        { "/lib/", "qdoc"         },
        { "/lib/", "libQtCore.so" }
#endif
    };

    const TElement* Elements;
    size_t Count;
    switch (QtVersion) {
        case '4' :
            Elements = Elements4;
            Count = sizeof(Elements4)/sizeof(Elements4[0]);
            break;
        case '5' :
            Elements = Elements5;
            Count = sizeof(Elements5)/sizeof(Elements5[0]);
            break;
        default :
            abort();
    }
    for (size_t i = 0; i < Count; ++i)
        find_files(NewQtPath + Elements[i].Dir, Elements[i].Name, pFilesList);
}

//------------------------------------------------------------------------------
// Patch one text file.

bool patch_text_file(const char* FileName,
                     const strmap& PatchValues)
{
    bool Result = false;
    printf("Patching text file %s...", FileName);

    FILE* File = fopen(FileName, "r+b");
    if (File!= NULL) {
        vector<char> Buf;
        long FileLength = get_file_size(File);
        if (FileLength <= 0) {
            Result = true;
        }
        else {
            Buf.resize(get_file_size(File));
            if (fread(Buf.data(), Buf.size(), 1, File) == 1) {
                for (strmap::const_iterator I = PatchValues.begin(); I != PatchValues.end(); ++I) {
                    string::size_type Delta = 0;
                    vector<char>::iterator Found;
                    while ((Found = search(Buf.begin() + Delta, Buf.end(),
                                           I->first.begin(), I->first.end()
#ifdef OS_WINDOWS
                                           , CaseInsensitiveComp
#endif
                            ))
                           != Buf.end())
                    {
                        Delta = Found - Buf.begin() + static_cast<int>(I->second.length());
                        Found = Buf.erase(Found, Found + I->first.length());
                        Buf.insert(Found, I->second.begin(), I->second.end());
                    }
                }
                rewind(File);
                zero_file(File);
                if (fwrite(Buf.data(), Buf.size(), 1, File) == 1)
                    Result = true;
            }
        }
        fclose(File);
    }

    printf(Result ? " OK\n" : " Failed!\n");
    return Result;
}

//------------------------------------------------------------------------------
// Patch list of text files.

bool patch_text_files(const strlist& Files,
                     const strmap& PatchValues)
{
    for (strlist::const_iterator I = Files.begin(); I != Files.end(); ++I)
        if (!patch_text_file(I->c_str(), PatchValues))
            return false;
    return true;
}
//------------------------------------------------------------------------------
// Patch one binary file.

bool patch_bin_file(const char* FileName,
                    const strmap& PatchValues)
{
    bool Result = false;
    printf("Patching binary file %s...", FileName);

    FILE* File = fopen(FileName, "r+b");
    if (File != NULL) {
        long BufSize = get_file_size(File);
        char* Buf = new char[BufSize];
        if (fread(Buf, BufSize, 1, File) == 1) {
            for (strmap::const_iterator I = PatchValues.begin(); I != PatchValues.end(); ++I) {
                char* First = Buf;
                while ((First = search(First, Buf + BufSize,
                                       I->first.begin(), I->first.end()))
                       != Buf + BufSize)
                {
                    strcpy(First, I->second.c_str());
                    First += I->second.length();
                    int Delta = static_cast<int>(I->first.length()) -
                                static_cast<int>(I->second.length());
                    if (Delta > 0) {
                        memset(First, 0, Delta);
                        First += Delta;
                    }
                }
            }
            rewind(File);
            if (fwrite(Buf, BufSize, 1, File) == 1)
                Result = true;
        }
        delete Buf;
        fclose(File);
    }

    printf(Result ? " OK\n" : " Failed!\n");
    return Result;
}

//------------------------------------------------------------------------------
// Patch list of binary files.

bool patch_bin_files(const strlist& Files,
                     const strmap& PatchValues)
{
    for (strlist::const_iterator I = Files.begin(); I != Files.end(); ++I)
        if (!patch_bin_file(I->c_str(), PatchValues))
            return false;
    return true;
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Backup file qt.conf if exists.

bool backup_qtconf(const string& QtDir)
{
    string Name = QtDir + "/bin/qt.conf";
    if (!is_file_exists(Name.c_str()))
        return true;
    printf("Renaming file qt.conf... ");
    bool Result = rename(Name.c_str(), (Name + BACKUP_SUFFIX).c_str()) == 0;
    printf(Result ? "OK\n" : "Failed!\n");
    return Result;
}

//------------------------------------------------------------------------------
// Restore file qt.conf if exists.

bool restore_qtconf(const string& QtDir)
{
    string Name = QtDir + "/bin/qt.conf";
    string BackupName = Name + BACKUP_SUFFIX;
    if (!is_file_exists(BackupName.c_str()))
        return true;
    printf("Restoring file qt.conf... ");
    bool Result = rename(BackupName.c_str(), Name.c_str()) == 0;
    printf(Result ? "OK\n" : "Failed!\n");
    return Result;
}

//------------------------------------------------------------------------------
// Remove file qt.conf if exists.

bool remove_qtconf(const string& QtDir)
{
    string Name = QtDir + "/bin/qt.conf";
    if (!is_file_exists(Name.c_str()))
        return true;
    printf("Removing file qt.conf... ");
    bool Result = remove(Name.c_str()) == 0;
    printf(Result ? "OK\n" : "Failed!\n");
    return Result;
}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

int main(int argc, char* argv[])
{
    printf("QtBinPatcher v1.1.2. Tool for patching paths in Qt binaries.\n"
           "(C) Yuri V. Krugloff, 2013-2014. http://www.tver-soft.org\n\n");

    strmap CmdlineOpts;
    if (!parse_cmdline_args(argc, argv, &CmdlineOpts)) {
        help();
        return -1;
    }
    if (CmdlineOpts.count(OPT_HELP) > 0) {
        help();
        return 0;
    }
    bool Backup = CmdlineOpts.count(OPT_NOBACKUP) == 0;

    string NewQtPath = get_new_qt_path(&CmdlineOpts);
    if (NewQtPath.empty()) {
        fprintf(stderr, "Error getting new path to Qt directory!\n");
        return -1;
    }
    if (NewQtPath.length() > QT_PATH_MAX_LEN) {
        fprintf(stderr, "Path to new Qt directory too long!\n"
                        "Path must be not longer as %i symbols.", QT_PATH_MAX_LEN);
        return -1;
    }

    char PipeBuffer[65536];
    if (!backup_qtconf(NewQtPath)) {
        fprintf(stderr, "Error renaming file qt.conf.");
        return -1;
    }
    bool b = get_qmake_output(NewQtPath, PipeBuffer, sizeof(PipeBuffer));
    if (!restore_qtconf(NewQtPath)) {
        fprintf(stderr, "Error restoring file qt.conf.");
        return -1;
    }
    if (!b) {
        fprintf(stderr, "Error getting qmake output!\n");
        return -1;
    }


    strmap QMakeValues;
    if (!parse_qmake_output(PipeBuffer, &QMakeValues)) {
        fprintf(stderr, "Error parsing qmake output!\n");
        return -1;
    }


    string StrQtVer = QMakeValues["QT_VERSION"];
    if (StrQtVer.empty()) {
        fprintf(stderr, "Qt version not found in qmake output.\n");
        return -1;
    }
    char QtVersion = StrQtVer[0];
    if (QtVersion != '4' && QtVersion != '5') {
        fprintf(stderr, "Unsupported Qt version (%c).\n", QtVersion);
        return -1;
    }

    if (Verbose)
        printf("Using file lists for Qt version %c.\n\n", QtVersion);

    string OldQtPath = QMakeValues["QT_INSTALL_PREFIX"];
    if (OldQtPath.empty()) {
        fprintf(stderr, "Error get old Qt path!\n");
        return -1;
    }
    if (Verbose)
        printf("Path to old Qt directory: %s\n\n", OldQtPath.c_str());

    if (streq(OldQtPath, NewQtPath)) {
        if (CmdlineOpts.count(OPT_FORCE) == 0) {
            printf("The new and the old pathes to Qt directory are the same. Patching not needed.\n");
            if (!remove_qtconf(NewQtPath)) {
                fprintf(stderr, "Error removing file qt.conf.");
                return -1;
            }
            return 0;
        }
        else {
            if (Verbose) {
                printf("The new and the old pathes to Qt directory are the same,\n"
                       "but forced patching requested.\n\n");
            }
        }
    }

    strmap PatchValues;
    strlist TxtFilesList;
    strlist BinFilesList;
    get_txt_files_for_patch(NewQtPath, QtVersion, &TxtFilesList);
    get_bin_files_for_patch(NewQtPath, QtVersion, &BinFilesList);
    strlist AllFilesList;
    if (Backup) {
        AllFilesList = BinFilesList;
        AllFilesList.insert(AllFilesList.end(),
                            TxtFilesList.begin(), TxtFilesList.end());
        if (!backup_files(AllFilesList)) {
            fprintf(stderr, "Error create backup copy of files!");
            return -1;
        }
        if (!backup_qtconf(NewQtPath)) {
            fprintf(stderr, "Error create backup copy of file qt.conf.");
            return -1;
        }
    }
    else {
        if (!remove_qtconf(NewQtPath)) {
            fprintf(stderr, "Error removing file qt.conf.");
        }
    }
    get_text_patch_values(OldQtPath, NewQtPath, &PatchValues);
    if (!patch_text_files(TxtFilesList, PatchValues)) {
        if (Backup) {
            restore_files(AllFilesList);
            restore_qtconf(NewQtPath);
        }
        return -1;
    }

    PatchValues.clear();
    get_bin_patch_values(QMakeValues, NewQtPath, &PatchValues);
    if (!patch_bin_files(BinFilesList, PatchValues)) {
        if (Backup) {
            restore_files(AllFilesList);
            restore_qtconf(NewQtPath);
        }
        return -1;
    }

    printf("\nPatch successfully completed.\n");

    return 0;
}

//------------------------------------------------------------------------------
