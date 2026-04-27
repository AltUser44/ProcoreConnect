import { Link } from "react-router-dom";
import { StaticInfoPage, StaticSection } from "../components/StaticInfoPage";

const UPDATED = "April 27, 2026";

export function Privacy() {
  return (
    <StaticInfoPage title="Privacy Policy">
      <p className="text-xs text-ink-500">Last updated: {UPDATED}</p>

      <p className="rounded-lg border border-ink-200 bg-ink-50 px-4 py-3 text-xs text-ink-600">
        This is a starter policy for development and early deployments. Have qualified counsel review
        and adapt it before you rely on it for compliance or customer commitments.
      </p>

      <StaticSection heading="Information we process">
        <p>
          When you use ProcoreConnect, we process account data you provide (such as email and
          credentials you enter), integration configuration (endpoints, secrets stored according to
          your deployment’s security model), sync and webhook metadata, and technical logs needed to
          operate the service.
        </p>
      </StaticSection>

      <StaticSection heading="How we use information">
        <p>
          We use this information to authenticate you, run the integrations you configure, display
          history in the dashboard, improve reliability, and secure the platform against abuse.
        </p>
      </StaticSection>

      <StaticSection heading="Retention">
        <p>
          Retention depends on how this instance is operated. Typically, account and integration
          data persist until you delete it or close the account, subject to backups and legal
          requirements.
        </p>
      </StaticSection>

      <StaticSection heading="Cookies and similar technologies">
        <p>
          The web application may use cookies or local storage for session and authentication
          tokens. See your browser settings to manage storage.
        </p>
      </StaticSection>

      <StaticSection heading="Third parties">
        <p>
          When you connect integrations, you direct us to exchange data with third-party APIs you
          choose. Those providers have their own terms and privacy practices.
        </p>
      </StaticSection>

      <StaticSection heading="Your choices">
        <p>
          You may request access, correction, or deletion of personal data where applicable law
          applies. Contact the operator of this deployment with privacy requests.
        </p>
      </StaticSection>

      <StaticSection heading="Changes">
        <p>
          We may update this policy from time to time. Material changes will be reflected by updating
          the “Last updated” date and, where appropriate, additional notice.
        </p>
      </StaticSection>

      <p className="text-xs text-ink-500">
        See also:{" "}
        <Link to="/terms" className="font-semibold text-brand-600 hover:underline">
          Terms of Service
        </Link>
        .
      </p>
    </StaticInfoPage>
  );
}
