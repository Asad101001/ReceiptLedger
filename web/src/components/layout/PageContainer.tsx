import React from 'react';
import clsx from 'clsx';

interface PageContainerProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  className?: string;
  maxWidth?: 'full' | '1920';
}

export const PageContainer: React.FC<PageContainerProps> = ({
  children,
  className,
  maxWidth = '1920',
  ...props
}) => {
  return (
    <div
      className={clsx(
        'w-full mx-auto p-4 xl:p-5 space-y-4',
        maxWidth === '1920' ? 'max-w-[1920px]' : 'max-w-full',
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};
