# Security Resources & Verification Tools

Free tools to verify the items in this checklist without spending money.

---

## Email Authentication (Section 2)

| Tool | What it checks | URL |
|---|---|---|
| MXToolbox DMARC | SPF + DKIM + DMARC status | https://mxtoolbox.com/dmarc.aspx |
| Google Admin Toolbox | Full email auth diagnostic | https://toolbox.googleapps.com/apps/checkmx/ |
| DMARC Analyzer | DMARC record checker | https://www.dmarcanalyzer.com/dmarc/checker/ |

---

## Security Headers (Section 5)

| Tool | What it checks | URL |
|---|---|---|
| securityheaders.com | All HTTP security headers | https://securityheaders.com |
| Mozilla Observatory | Full site security scan | https://observatory.mozilla.org |
| SSL Labs | TLS/SSL configuration | https://www.ssllabs.com/ssltest/ |

---

## Cloud Storage Exposure (Section 5)

| Tool | What it checks | URL |
|---|---|---|
| GrayhatWarfare | Public S3, Azure, GCS buckets | https://buckets.grayhatwarfare.com |
| AWS Trusted Advisor | S3 bucket access check | AWS Console |
| Azure Security Center | Storage access audit | Azure Portal |

---

## Credential Exposure (Sections 1 + 6)

| Tool | What it checks | URL |
|---|---|---|
| Have I Been Pwned | Email in breach databases | https://haveibeenpwned.com |
| Firefox Monitor | Ongoing breach monitoring (free) | https://monitor.firefox.com |
| DeHashed | More comprehensive breach search | https://dehashed.com (paid) |

---

## Open Port / Attack Surface

| Tool | What it checks | URL |
|---|---|---|
| Shodan | What the internet sees on your IP | https://www.shodan.io |
| nmap (local) | Open ports from outside | `nmap -sV yourdomain.com` |
| Censys | Certificate and port exposure | https://search.censys.io |

---

## Phishing Simulation

| Tool | What it checks | URL |
|---|---|---|
| GoPhish | Self-hosted phishing simulator | https://getgophish.com |
| KnowBe4 Free Tools | Phishing awareness resources | https://www.knowbe4.com/free-it-security-tools |

---

*Last updated: May 2026. Submit additions via GitHub Issues.*
