# Hotel Management Quickstart App

## Introduction
[Couchbase Mobile](https://docs.couchbase.com/home/mobile.html) brings the power of NoSQL to the edge with offline-first data sync. It is comprised of three components:

- [Couchbase Lite](https://docs.couchbase.com/couchbase-lite/current/index.html), local-first, embedded, NoSQL JSON Document database for your mobile, desktop and embedded apps.
- Sync Gateway, an internet-facing component mechanism that securely syncs data between Couchbase Lite clients and Couchbase Server.
- Couchbase Server, a highly scalable, distributed NoSQL database platform backing data store.

Couchbase Server and Sync Gateway can be deployed in a self-managed configuration, or developers can leverage **Capella**, Couchbase's fully managed offering. This tutorial uses Capella App Services as a backend data store and sync for the Couchbase Lite app. Conveniently, Capella offers a [**free tier**](https://docs.couchbase.com/cloud/get-started/create-account.html), which allows developers to get started with Capella and App Services for free to explore the core features of Couchbase.

### Capella Cluster Setup
Sign up for Capella Free Tier and follow the steps to deploy a free tier cluster.

When you create a free tier cluster, it will automatically import a **travel-sample** bucket with datasets that we will use in this app. If you deleted the travel-sample bucket, you can reimport it from Data Tools → Import tab.

### Create a new App Service
Follow [instructions](https://docs.couchbase.com/cloud/get-started/create-account.html#app-services) to create a free tier App Service that links to your free tier cluster created in the previous step.

On the Create App Services page:

- Enter a name for your app service (e.g. `demo-app-service`).
- Under the **Linked Cluster** section, select your demo-cluster from the drop-down list.
- Click the **Create App Service** button.

> It may take between 5 and 25 minutes for the new App Service to be created.

### Create a new App Endpoint
Once the App Service is created and its status is listed as `Healthy`, click on the App Service name you just created.

On the App Endpoints screen, click the **Create App Endpoint** button.

On the Create App Endpoint page:

- Enter a name (e.g. `hotels`) in the **App Endpoint Name** field.
- For **Bucket**, select `travel-sample`.
- For **Scope**, select `inventory`.

Under **Choose collections to link**:

- Enable the `hotel` collection by switching the Link toggle to On.

Click the **Create App Endpoint** button. You'll be redirected to the App Endpoints list.

### Set up App Endpoint security
Click on the newly created endpoint (e.g. `hotels`) to view the App Endpoint details.

On the **Security** tab:

- If a message appears stating that the App Endpoint is paused, click the **Resume app endpoint** link
  > This may take a few seconds.

We will use the default access control and data validation function, so no changes are required there. By default, all documents in a collection are assigned to a channel with a name associated with that collection.

Click on the **App Users** tab in the left-hand navigation menu.

Click the **Create App User** button.

On the Create App User page:

- Enter a username and password for the new user
  *(Be sure to save these credentials — you'll need them for the app configuration)*

Click the **Configure Access Grants** link to expand the section.

Under **Assign Channels**:

- Locate the `hotel` collection under **Linked Collections**.
- Enter the Admin Channel name `hotel` and hit the Enter key.
  > It should appear as a chip or tag.

Click the **Create App User** button.

### Get the App Endpoint URL
Click on the **Connect** tab in the navigation header.

The **Connect** page will appear, showing the Public Connection string.

- Click the **copy icon** next to the URL to copy the App Endpoint URL to your clipboard.
  > You'll need this in the app configuration file.

## Getting Help
You can reach out on the GitHub repo or join our community of developers:

- [Discord community](https://bit.ly/3NbK5vg): Chat with Couchbase developers and ask questions.
- [Stack Overflow community](https://stackoverflow.com/tags/couchbase/info/): Ask questions.
- [Developer Portal](https://www.couchbase.com/developer): More information including tutorials and learning paths.

## Repo Structure
The repo is organized as follows:

- iOS: This folder includes source code corresponding to the iOS version of the Hotel Quickstart application. Follow the instructions in the [README.md](iOS/README.md) file in the folder to build and run the iOS app.

- Android: This folder includes source code corresponding to the Android version of the Hotel Quickstart application. Follow the instructions in the [README.md](Android/README.md) file in that folder to build and run the Android app.

- Web: This folder includes source code corresponding to the Web (JavaScript/React) version of the Hotel Quickstart application. Follow the instructions in the [README.md](web/README.md) file in that folder to build and run the web app.