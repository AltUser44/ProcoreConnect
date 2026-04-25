interface HexLogoProps {
  size?: number;
  className?: string;
  showLabel?: boolean;
}

export function HexLogo({ size = 36, className = "", showLabel = true }: HexLogoProps) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <svg
        width={size}
        height={size}
        viewBox="0 0 40 40"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        <path
          d="M20 2L36.32 11.5v17L20 38L3.68 28.5v-17L20 2z"
          fill="#f24f00"
        />
        {showLabel && (
          <text
            x="20"
            y="25"
            textAnchor="middle"
            fontSize="14"
            fontWeight="800"
            fontFamily="Inter, sans-serif"
            fill="white"
            letterSpacing="-0.5"
          >
            PC
          </text>
        )}
      </svg>
    </span>
  );
}
