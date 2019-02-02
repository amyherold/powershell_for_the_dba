

CREATE TABLE [dbo].[Deployments](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TicketID] [varchar](10) NULL,
	[OrderOfExec] [int] NULL,
	[ServerID] [tinyint] NULL,
	[Database] [varchar](40) NULL,
	[Author] [varchar](10) NULL,
	[Script] [varchar](1000) NULL,
	[Notes] [varchar](1000) NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[ModifyDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Deployments] ADD  CONSTRAINT [DC_ReleaseData_CreateDate]  DEFAULT (sysdatetime()) FOR [CreateDate]
GO

ALTER TABLE [dbo].[Deployments] ADD  CONSTRAINT [DC_ReleaseData_ModifyDate]  DEFAULT (sysdatetime()) FOR [ModifyDate]
GO


