
/****** Object:  Table [dbo].[ADGroupMembers]    Script Date: 11/8/2018 6:56:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADGroupMembers](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MemberName] [varchar](200) NULL,
	[MemberLogin] [varchar](50) NULL,
	[GroupID] [int] NULL,
	[IsEnabled] [bit] NULL,
	[domain] [varchar](50) NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ADUsers]    Script Date: 11/8/2018 6:56:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ADUsers](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MemberName] [varchar](200) NULL,
	[MemberLogin] [varchar](50) NULL,
	[IsEnabled] [bit] NULL,
	[domain] [varchar](50) NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[GroupRelationships]    Script Date: 11/8/2018 6:56:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[GroupRelationships](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[groupid] [int] NULL,
	[parentid] [int] NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Groups]    Script Date: 11/8/2018 6:56:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Groups](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[group_name] [varchar](200) NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ServerGroups]    Script Date: 11/8/2018 6:56:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerGroups](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[server_name] [varchar](100) NULL,
	[group_name] [varchar](200) NULL,
	[server_id] [int] NULL,
	[group_id] [int] NULL,
	[sysadmin] [bit] NULL,
	[securityadmin] [bit] NULL,
	[serveradmin] [bit] NULL,
	[setupadmin] [bit] NULL,
	[processadmin] [bit] NULL,
	[diskadmin] [bit] NULL,
	[dbcreator] [bit] NULL,
	[bulkadmin] [bit] NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ServerGroupsPermissions]    Script Date: 11/8/2018 6:56:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerGroupsPermissions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[servergroupid] [int] NULL,
	[group_permissions] [varchar](max) NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ServerList]    Script Date: 11/8/2018 6:56:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerList](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[server_name] [varchar](100) NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ServerUsers]    Script Date: 11/8/2018 6:56:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerUsers](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[server_name] [varchar](100) NULL,
	[user_name] [varchar](200) NULL,
	[server_id] [int] NULL,
	[user_id] [int] NULL,
	[sysadmin] [bit] NULL,
	[securityadmin] [bit] NULL,
	[serveradmin] [bit] NULL,
	[setupadmin] [bit] NULL,
	[processadmin] [bit] NULL,
	[diskadmin] [bit] NULL,
	[dbcreator] [bit] NULL,
	[bulkadmin] [bit] NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[UserLogins]    Script Date: 11/8/2018 6:56:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UserLogins](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_name] [varchar](200) NULL,
	[create_date] [datetime2](7) NULL,
	[update_date] [datetime2](7) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ADGroupMembers] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[ADUsers] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[GroupRelationships] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[Groups] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[ServerGroups] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[ServerGroupsPermissions] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[ServerList] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[ServerUsers] ADD  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[UserLogins] ADD  DEFAULT (getdate()) FOR [create_date]
GO


