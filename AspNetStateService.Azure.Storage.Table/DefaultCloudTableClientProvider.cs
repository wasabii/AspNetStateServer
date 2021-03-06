﻿using System;

using Autofac.Features.AttributeFilters;

using Cogito.Autofac;

using Microsoft.Azure.Cosmos.Table;

namespace AspNetStateService.Azure.Storage.Table
{

    /// <summary>
    /// Default provider of <see cref="CloudTableClient"/> instances.
    /// </summary>
    [RegisterAs(typeof(ICloudTableClientProvider))]
    [RegisterWithAttributeFiltering]
    public class DefaultCloudTableClientProvider : ICloudTableClientProvider
    {

        readonly CloudStorageAccount account;

        /// <summary>
        /// Initializes a new instance.
        /// </summary>
        /// <param name="account"></param>
        public DefaultCloudTableClientProvider([KeyFilter(StateObjectTableDataStore.TypeNameKey)] CloudStorageAccount account)
        {
            this.account = account ?? throw new ArgumentNullException(nameof(account));
        }

        public CloudTableClient GetTableClient()
        {
            return account.CreateCloudTableClient();
        }

    }

}
