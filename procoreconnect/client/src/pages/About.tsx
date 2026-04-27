import { Link } from "react-router-dom";
import { StaticInfoPage, StaticSection } from "../components/StaticInfoPage";

const UPDATED = "April 27, 2026";

export function About() {
  return (
    <StaticInfoPage title="About ProcoreConnect">
      <p className="text-xs text-ink-500">Last updated: {UPDATED}</p>

      <StaticSection heading="What we do">
        <p>
          ProcoreConnect is an integration platform that helps you connect internal workflows to
          third-party HTTP APIs. You define integrations, run syncs, review logs, and accept signed
          webhooks from your partners—all from one dashboard.
        </p>
      </StaticSection>

      <StaticSection heading="Who it’s for">
        <p>
          Teams that need a practical control plane for API credentials, sync history, and webhook
          verification without building that plumbing from scratch for every integration.
        </p>
      </StaticSection>

      <StaticSection heading="Contact">
        <p>
          For product or account questions, reach out through the contact channel you use with the
          operator of this deployment. If you are evaluating ProcoreConnect in production, ensure
          your organization’s policies cover data handling described in our{" "}
          <Link to="/privacy" className="font-semibold text-brand-600 hover:underline">
            Privacy Policy
          </Link>
          .
        </p>
      </StaticSection>
    </StaticInfoPage>
  );
}
