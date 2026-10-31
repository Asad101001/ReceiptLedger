import React from 'react';
import clsx from 'clsx';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  className?: string;
  variant?: 'white' | 'subtle' | 'dark';
  noPadding?: boolean;
}

export const Card: React.FC<CardProps> = ({
  children,
  className,
  variant = 'white',
  noPadding = false,
  ...props
}) => {
  const variantStyles = {
    white: 'bg-white border-[#CBD5E1] text-[#0F172A]',
    subtle: 'bg-[#F8FAFC] border-[#E2E8F0] text-[#0F172A]',
    dark: 'bg-[#0F172A] border-[#1E293B] text-white',
  };

  return (
    <div
      className={clsx(
        'border rounded-xl transition-colors',
        variantStyles[variant],
        noPadding ? 'p-0' : 'p-4',
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};
