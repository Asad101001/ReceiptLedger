import React from 'react';

export type ProjectIconName = 'app' | 'capture' | 'ledger' | 'review' | 'settings';

interface ProjectIconProps {
  name: ProjectIconName;
  className?: string;
}

export const ProjectIcon: React.FC<ProjectIconProps> = ({ name, className = 'w-5 h-5' }) => {
  switch (name) {
    case 'app':
      return (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 500 500"
          fill="none"
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          {/* RECEIPT OUTLINE */}
          <path
            d="M 140 100 L 340 100 L 340 370 L 323.3 355 L 306.6 370 L 290 355 L 273.3 370 L 256.6 355 L 240 370 L 223.3 355 L 206.6 370 L 190 355 L 173.3 370 L 156.6 355 L 140 370 Z"
            strokeWidth="20"
            fill="none"
          />
          {/* RECEIPT HEADER & LINES */}
          <line x1="180" y1="140" x2="290" y2="140" strokeWidth="16" />
          <line x1="200" y1="165" x2="270" y2="165" strokeWidth="12" />
          <line x1="165" y1="195" x2="295" y2="195" strokeWidth="14" />
          <line x1="185" y1="220" x2="240" y2="220" strokeWidth="12" />
          <line x1="185" y1="245" x2="235" y2="245" strokeWidth="12" />
          <line x1="165" y1="280" x2="245" y2="280" strokeWidth="14" />
          <line x1="285" y1="280" x2="315" y2="280" strokeWidth="14" />
          {/* OVERLAPPING PEN (DIAGONAL) */}
          <path d="M 243 328 L 255 334 L 236 348 Z" fill="currentColor" strokeWidth="4" />
          <path d="M 255 334 L 315 215 L 338 226 L 278 345 Z" fill="currentColor" strokeWidth="6" />
          <path d="M 320 205 L 360 125 C 368 109, 380 120, 372 135 L 343 216 Z" fill="currentColor" strokeWidth="6" />
        </svg>
      );

    case 'capture':
      return (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 500 500"
          fill="none"
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          {/* Camera Body */}
          <path
            d="M 100 175 L 340 175 C 350 175 350 160 350 160 L 270 160 L 255 145 L 180 145 L 165 160 L 125 160 C 125 160 100 160 100 175 Z M 100 175 L 100 325 C 100 335 110 340 120 340 L 320 340 C 330 340 340 335 340 325 L 340 175"
            strokeWidth="20"
          />
          {/* Lens */}
          <circle cx="230" cy="250" r="52" strokeWidth="20" />
          <circle cx="230" cy="250" r="32" strokeWidth="14" />
          {/* Overlay Receipt Document */}
          <path
            d="M 300 190 L 395 190 L 395 330 L 383 320 L 371 330 L 359 320 L 347 330 L 335 320 L 323 330 L 311 320 L 300 330 Z"
            strokeWidth="18"
            fill="currentColor"
            fillOpacity="0.1"
          />
          <line x1="318" y1="215" x2="377" y2="215" strokeWidth="12" />
          <line x1="318" y1="245" x2="365" y2="245" strokeWidth="12" />
          <line x1="318" y1="275" x2="377" y2="275" strokeWidth="12" />
        </svg>
      );

    case 'ledger':
      return (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 500 500"
          fill="none"
          stroke="currentColor"
          strokeWidth="14"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={className}
        >
          {/* Outer Book Cover */}
          <path d="M 60 120 L 250 135 L 440 120 L 440 385 Q 250 400 250 395 Q 250 400 60 385 Z" strokeWidth="18" />
          {/* Left Page Frame */}
          <path d="M 80 115 L 240 128 L 240 378 L 80 365 Z" strokeWidth="14" />
          <line x1="80" y1="155" x2="240" y2="168" strokeWidth="10" />
          <line x1="80" y1="205" x2="240" y2="218" strokeWidth="10" />
          <line x1="80" y1="255" x2="240" y2="268" strokeWidth="10" />
          <line x1="80" y1="305" x2="240" y2="318" strokeWidth="10" />
          <line x1="160" y1="121" x2="160" y2="371" strokeWidth="10" />
          {/* Right Page Frame */}
          <path d="M 260 128 L 420 115 L 420 365 L 260 378 Z" strokeWidth="14" />
          <line x1="260" y1="168" x2="420" y2="155" strokeWidth="10" />
          <line x1="260" y1="218" x2="420" y2="205" strokeWidth="10" />
          <line x1="260" y1="268" x2="420" y2="255" strokeWidth="10" />
          <line x1="260" y1="318" x2="420" y2="305" strokeWidth="10" />
          <line x1="340" y1="121" x2="340" y2="371" strokeWidth="10" />
        </svg>
      );

    case 'review':
      return (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 500 500"
          fill="none"
          stroke="currentColor"
          strokeLinejoin="round"
          className={className}
        >
          {/* Document Body */}
          <rect x="130" y="100" width="240" height="300" rx="20" ry="20" strokeWidth="24" />
          <line x1="160" y1="140" x2="340" y2="140" strokeWidth="16" strokeLinecap="round" />
          <line x1="160" y1="330" x2="340" y2="330" strokeWidth="16" strokeLinecap="round" />
          {/* Magnifying Glass */}
          <circle cx="235" cy="240" r="75" strokeWidth="26" fill="none" />
          <line x1="290" y1="295" x2="375" y2="380" strokeWidth="34" strokeLinecap="round" />
        </svg>
      );

    case 'settings':
      return (
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 500 500"
          fill="currentColor"
          className={className}
        >
          <path
            fillRule="evenodd"
            d="
            M 225,83 L 275,83 L 280,128 A 120,120 0 0,1 322,145 L 362,125 L 398,160 L 378,200 A 120,120 0 0,1 395,242 L 440,247 L 440,297 L 395,302 A 120,120 0 0,1 378,344 L 398,384 L 362,419 L 322,399 A 120,120 0 0,1 280,416 L 275,461 L 225,461 L 220,416 A 120,120 0 0,1 178,399 L 138,419 L 102,384 L 122,344 A 120,120 0 0,1 105,302 L 60,297 L 60,247 L 105,242 A 120,120 0 0,1 122,200 L 102,160 L 138,125 L 178,145 A 120,120 0 0,1 220,128 Z
            M 250,170 A 102,102 0 1,0 250,374 A 102,102 0 1,0 250,170 Z
          "
          />
        </svg>
      );
  }
};
