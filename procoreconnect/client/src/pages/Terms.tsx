import { Link } from "react-router-dom";
import { StaticInfoPage, StaticSection } from "../components/StaticInfoPage";

const UPDATED = "April 27, 2026";

export function Terms() {
  return (
    <StaticInfoPage title="Terms of Service">
      <p className="text-xs text-ink-500">Last updated: {UPDATED}</p>

      <p className="rounded-lg border border-ink-200 bg-ink-50 px-4 py-3 text-xs text-ink-600">
        This is a starter agreement for development and early deployments. Have qualified counsel
        review and adapt it before you rely on it for customers or production use.
      </p>

      <StaticSection heading="The service">
        <p>
          ProcoreConnect provides tools to configure integrations with third-party APIs, run syncs,
          review logs, and verify webhooks. Features and availability may change as the product
          evolves.
        </p>
      </StaticSection>

      <StaticSection heading="Your account">
        <p>
          You are responsible for maintaining the confidentiality of your credentials and for all
          activity under your account. You must provide accurate registration information and notify
          the operator of unauthorized use.
        </p>
      </StaticSection>

      <StaticSection heading="Acceptable use">
        <p>You agree not to misuse the service, including by attempting to:</p>
        <ul className="list-inside list-disc space-y-2 pl-1">
          <li>probe, scan, or test vulnerabilities without authorization;</li>
          <li>overload or disrupt infrastructure or other customers;</li>
          <li>use the service to violate law or third-party rights;</li>
          <li>access data you are not authorized to access.</li>
        </ul>
      </StaticSection>

      <StaticSection heading="Customer data and integrations">
        <p>
          You control the integrations you configure and the instructions you give the platform.
          You are responsible for compliance with laws and contracts that apply to your data and
          your use of third-party APIs.
        </p>
      </StaticSection>

      <StaticSection heading="Disclaimers">
        <p>
          The service is provided “as is” to the extent permitted by law. We do not warrant
          uninterrupted or error-free operation or that integrations will meet every use case.
        </p>
      </StaticSection>

      <StaticSection heading="Limitation of liability">
        <p>
          To the maximum extent permitted by law, the operator’s total liability for claims arising
          out of these terms or the service will not exceed the amounts you paid for the service in
          the twelve months before the claim (or fifty dollars if no fees applied).
        </p>
      </StaticSection>

      <StaticSection heading="Termination">
        <p>
          You may stop using the service at any time. We may suspend or terminate access for
          violations of these terms or risks to security or other users, with notice where
          reasonable.
        </p>
      </StaticSection>

      <StaticSection heading="Changes">
        <p>
          We may update these terms. Continued use after changes become effective constitutes
          acceptance of the revised terms where permitted by law.
        </p>
      </StaticSection>

      <p className="text-xs text-ink-500">
        See also:{" "}
        <Link to="/privacy" className="font-semibold text-brand-600 hover:underline">
          Privacy Policy
        </Link>
        .
      </p>
    </StaticInfoPage>
  );
}
