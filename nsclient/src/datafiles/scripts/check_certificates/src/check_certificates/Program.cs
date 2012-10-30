/* 
 * 2012 - Sölvi Páll Á. / Reiknistofa bankanna
 * No guarantees made about anything
 */

using System;
using System.Collections.Generic;
using System.Text;
using System.Linq;
using System.Security.Cryptography.X509Certificates;

namespace check_certificates
{
    class Program
    {
        const int EXIT_UNKNOWN = 3;
        const int EXIT_CRIT = 2;
        const int EXIT_WARN = 1;
        const int EXIT_OK = 0;

        static private bool parse_arguments(string[] args, ref int warn_in_days, ref int crit_in_days) {
            if (args.Length != 2) {
                return false;
            }

            try {
                warn_in_days = Convert.ToInt32(args[0]);
                crit_in_days = Convert.ToInt32(args[1]);
            }
            catch (FormatException) {
                return false;
            }

            if (!(warn_in_days >= crit_in_days)) {
                return false;
            }

            return true;
        }

        static List<X509Certificate2> get_expiring_certificates(int days) {
            X509Store local_machine_store = new X509Store(StoreName.My, StoreLocation.LocalMachine);
            local_machine_store.Open(OpenFlags.ReadOnly);

            DateTime expiration_date = DateTime.Now.AddDays(days);
            List<X509Certificate2> certificate_list = new List<X509Certificate2>();

            foreach (X509Certificate2 cert in local_machine_store.Certificates) {
                if (cert.HasPrivateKey && DateTime.Compare(expiration_date, cert.NotAfter) >= 0) {
                    certificate_list.Add(cert);
                }
            }

            return certificate_list;
        }

        static string find_certificate_name(X509Certificate2 cert) {
            string cert_name = cert.GetNameInfo(X509NameType.SimpleName, false);

            if (cert_name.Count() == 0) {
                cert_name = cert.GetNameInfo(X509NameType.DnsName, false);
            }

            if (cert_name.Count() == 0) {
                cert_name = cert.GetNameInfo(X509NameType.DnsFromAlternativeName, false);
            }

            return cert_name;
        }

        static void output_certlist(List<X509Certificate2> certificates) {
            bool first = true;
            foreach (X509Certificate2 cert in certificates) {
                if (!first) {
                    Console.Write(", ");
                }
                first = false;

                Console.Write("[\"" + find_certificate_name(cert) + "\" / " + cert.NotAfter.ToString() + "]");
            }
        }

        static int Main(string[] args) {
            int warn_in_days = 0;
            int crit_in_days = 0;

            if (parse_arguments(args, ref warn_in_days, ref crit_in_days)) {

                List<X509Certificate2> expired_certs = get_expiring_certificates(0);
                List<X509Certificate2> crit_certs = get_expiring_certificates(crit_in_days).Except(expired_certs).ToList();
                List<X509Certificate2> warn_certs = get_expiring_certificates(warn_in_days).Except(expired_certs).Except(crit_certs).ToList();


                if (expired_certs.Count > 0) {
                    Console.Write("CRITICAL: Expired certificates: ");
                    output_certlist(expired_certs);
                    Console.Write("\n");

                    Console.Write("Certificates expiring in " + crit_in_days + " days: ");
                    output_certlist(crit_certs);
                    Console.Write("\n");

                    Console.Write("Certificates expiring in " + warn_in_days + " days: ");
                    output_certlist(warn_certs);
                    Console.Write("\n");

                    return EXIT_CRIT;
                }

                if (crit_certs.Count > 0) {
                    Console.Write("CRITICAL: Certificates expiring in " + crit_in_days + " days: ");
                    output_certlist(crit_certs);
                    Console.Write("\n");

                    Console.Write("Certificates expiring in " + warn_in_days + " days: ");
                    output_certlist(warn_certs);
                    Console.Write("\n");

                    return EXIT_CRIT;
                }

                if (warn_certs.Count > 0) {
                    Console.Write("WARNING:  Certificates expiring in " + warn_in_days + " days: ");
                    output_certlist(warn_certs);

                    return EXIT_WARN;
                }

                Console.WriteLine("OK:  No certificates expiring in " + warn_in_days + "days.");
                return EXIT_OK;
            } else {
                Console.WriteLine("Incorrect arguments");
                Console.WriteLine("Call as: ");
                Console.WriteLine("check_certificates.exe <warn_in_days> <crit_in_days>");
                Console.WriteLine("warn_in_days must be greater than or equal to crit_in_days.");

                return EXIT_UNKNOWN;
            }
        }
    }
}
