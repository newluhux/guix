;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2018 Fis Trivial <ybbs.daans@hotmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages opencl)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages libedit)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

;; This file adds OpenCL implementation related packages. Due to the fact that
;; OpenCL devices are not available during build (store environment), tests are
;; all disabled.
;; Check https://lists.gnu.org/archive/html/guix-devel/2018-04/msg00293.html

(define (make-opencl-headers major-version subversion)
  (let ((commit "e986688daf750633898dfd3994e14a9e618f2aa5")
        (revision "0"))
    (package
      (name "opencl-headers")
      (version (git-version
                (string-append major-version "." subversion ".0")
                revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/KhronosGroup/OpenCL-Headers.git")
                      (commit commit)))
                (file-name (string-append name "-" commit))
                (sha256
                 (base32
                  "176ydpbyws5nr4av6hf8p41pkhc0rc4m4vrah9w6gp2fw2i32838"))))
      (build-system gnu-build-system)
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (delete 'configure)
           (delete 'build)
           (delete 'check)
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (copy-recursively (string-append "./opencl" (string-append
                                                            ,major-version
                                                            ,subversion) "/CL")
                                 (string-append
                                  (assoc-ref outputs "out")
                                  "/include/CL")))))))
      (synopsis "The Khronos OpenCL headers")
      (description
       "This package provides the C headers by Khronos for OpenCL
programming.")
      (home-page "https://www.khronos.org/registry/OpenCL/")
      (license license:expat))))

(define-public opencl-headers-2.2
  (make-opencl-headers "2" "2"))
(define-public opencl-headers-2.1
  (make-opencl-headers "2" "1"))
(define-public opencl-headers-2.0
  (make-opencl-headers "2" "0"))
(define-public opencl-headers-1.2
  (make-opencl-headers "1" "2"))
(define-public opencl-headers-1.1
  (make-opencl-headers "1" "1"))
(define-public opencl-headers-1.0
  (make-opencl-headers "1" "0"))

(define-public opencl-headers opencl-headers-2.2)

(define-public opencl-clhpp
  (package
    (name "opencl-clhpp")
    (version "2.0.10")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/KhronosGroup/OpenCL-CLHPP/archive/v"
                    version ".tar.gz"))
              (sha256
               (base32
                "0awg6yznbz3h285kmnd47fykx2qa34a07sr4x1657yn3jmi4a9zs"))
              (file-name (string-append name "-" version ".tar.gz"))))
    (native-inputs
     `(("python" ,python-wrapper)))
    (propagated-inputs
     `(("opencl-headers" ,opencl-headers)))
    (arguments
     `(#:configure-flags
       (let ((out (assoc-ref %outputs "out")))
         (list
          "-DBUILD_EXAMPLES=OFF"
          "-DBUILD_TESTS=OFF"
          (string-append "-DCMAKE_INSTALL_PREFIX="
                         (assoc-ref %outputs "out")
                         "/include")))
       ;; regression tests requires a lot more dependencies
       #:tests? #f))
    (build-system cmake-build-system)
    (home-page "http://github.khronos.org/OpenCL-CLHPP/")
    (synopsis "Khronos OpenCL-CLHPP")
    (description
     "This package provides the @dfn{host API} C++ headers for OpenCL.")
    (license license:expat)))

(define-public ocl-icd
  (package
    (name "ocl-icd")
    (version "2.2.12")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://forge.imag.fr/frs/download.php/836/ocl-icd-"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1x2dr8p4dkfds56r38av360i3nv1y3326jmshxvjngaf6mlg6rbn"))
              (modules '((guix build utils)))
              (snippet
               '(delete-file-recursively "khronos-headers"))))
    (native-inputs
     `(("opencl-headers" ,opencl-headers)
       ("ruby" ,ruby)))
    (inputs
     `(("libgcrypt" ,libgcrypt)))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags '("DEBUG_OCL_ICD=1")))
    (native-search-paths
     (list (search-path-specification
            (variable "OPENCL_VENDOR_PATH")
            (files '("etc/OpenCL/vendors")))))
    (search-paths native-search-paths)
    (home-page "https://forge.imag.fr/projects/ocl-icd/")
    (synopsis "OpenCL loader for Installable Client Drivers (ICDs)")
    (description
     "OpenCL implementations are provided as ICDs (Installable Client
Drivers).  An OpenCL program can use several ICDs thanks to the use of an ICD
Loader as provided by this package.")
    (license license:bsd-2)))

(define-public clinfo
  (package
    (name "clinfo")
    (version "2.2.18.04.06")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Oblomov/clinfo/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0v7cy01irwdgns6lzaprkmm0502pp5a24zhhffydxz1sgfjj2w7p"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("opencl-headers" ,opencl-headers)))
    (inputs
     `(("ocl-icd" ,ocl-icd)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
           (lambda _
             (let ((cores (number->string (parallel-job-count))))
               (setenv "CC" "gcc")
               (invoke "make" "-j" cores))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (invoke "make" "install" (string-append
                                       "PREFIX="
                                       (assoc-ref outputs "out"))))))
       #:tests? #f))
    (home-page "https://github.com/Oblomov/clinfo")
    (synopsis "Print information about OpenCL platforms and devices")
    ;; Only the implementation installed via Guix will be detected.
    (description
     "This package provides the @command{clinfo} command that enumerates all
possible (known) properties of the OpenCL platform and devices available on
the system.")
    (license license:cc0)))

(define-public beignet
  (package
    (name "beignet")
    (version "1.3.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/intel/beignet/archive/Release_v"
                    version
                    ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "18r0lq3dkd4yn6bxa45s2lrr9cjbg70nr2nn6xablvgqwzw0jb0r"))
              (patches (search-patches "beignet-correct-file-names.patch"))
              (modules '((guix build utils)))
              (snippet
               ;; There's a suspicious .isa binary file under kernels/.
               ;; Remove it.
               '(for-each delete-file (find-files "." "\\.isa$")))))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("python" ,python)))
    (inputs `(("clang@3.7" ,clang-3.7)
              ("clang-runtime@3.7" ,clang-runtime-3.7)
              ("glu" ,glu)
              ("llvm@3.7" ,llvm-3.7)
              ("libdrm" ,libdrm)
              ("libedit" ,libedit)
              ("libpthread-stubs", libpthread-stubs)
              ("libsm" ,libsm)
              ("libva" ,libva)
              ("libxfixes" ,libxfixes)
              ("libxext" ,libxext)
              ("mesa-utils" ,mesa-utils)
              ("ncurses" ,ncurses)
              ("ocl-icd" ,ocl-icd)
              ("opencl-headers" ,opencl-headers)
              ("xextproto" ,xextproto)
              ("zlib" ,zlib)))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags
       (list (string-append "-DCLANG_LIBRARY_DIR="
                            (assoc-ref %build-inputs "clang@3.7") "/lib")
             "-DENABLE_GL_SHARING=ON"
             "-DEXPERIMENTAL_DOUBLE=ON")

       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'remove-headers
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (delete-file-recursively
                (string-append out "/include"))
               #t)))
         (add-after 'remove-headers 'install-kernels
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (builddir (getcwd))
                    (source-dir (string-append
                                 builddir
                                 "/../beignet-Release_v1.3.2/kernels")))
               (copy-recursively source-dir
                                 (string-append out "/lib/beignet/kernels"))
               #t))))
       ;; Beignet tries to find GPU when running tests, which is not available
       ;; during build.
       #:tests? #f))
    (home-page "https://wiki.freedesktop.org/www/Software/Beignet/")
    (synopsis "OpenCL framework for Intel GPUs")
    (description
     "Beignet is an implementation of the OpenCL specification.  This code
base contains the code to run OpenCL programs on Intel GPUs---IvyBridge,
Haswell, Skylake, Apollolake, etc.  It defines and implements the OpenCL host
functions required to initialize the device, create the command queues, the
kernels and the programs, and run them on the GPU.  The code also contains a
back-end for the LLVM compiler framework.")
    (license license:lgpl2.1+)))
