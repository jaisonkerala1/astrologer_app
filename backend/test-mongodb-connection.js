const mongoose = require('mongoose');
require('dotenv').config();

const testMongoDBConnection = async () => {
  try {
    console.log('🔍 Testing MongoDB Connection...');
    console.log('MONGODB_URI:', process.env.MONGODB_URI ? 'SET' : 'NOT SET');
    
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI environment variable is not set');
    }
    
    const uri = process.env.MONGODB_URI;
    console.log('URI format:', uri.includes('mongodb+srv://') ? 'SRV' : 'Standard');
    console.log('URI length:', uri.length);
    
    // Test connection with detailed logging
    await mongoose.connect(uri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      bufferCommands: false,
      bufferMaxEntries: 0,
    });
    
    console.log('✅ Connected to MongoDB successfully!');
    console.log('Database name:', mongoose.connection.db.databaseName);
    console.log('Host:', mongoose.connection.host);
    console.log('Port:', mongoose.connection.port);
    
    // Test a simple operation
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('Available collections:', collections.map(c => c.name));
    
    // Test creating a simple document
    const testCollection = mongoose.connection.db.collection('test');
    const result = await testCollection.insertOne({ test: 'connection', timestamp: new Date() });
    console.log('Test document inserted:', result.insertedId);
    
    // Clean up test document
    await testCollection.deleteOne({ _id: result.insertedId });
    console.log('Test document cleaned up');
    
    await mongoose.disconnect();
    console.log('✅ MongoDB connection test completed successfully!');
    
  } catch (error) {
    console.error('❌ MongoDB connection test failed:');
    console.error('Error message:', error.message);
    console.error('Error code:', error.code);
    console.error('Error name:', error.name);
    
    if (error.message.includes('authentication failed')) {
      console.error('🔑 Authentication failed - check username/password');
    } else if (error.message.includes('timeout')) {
      console.error('⏰ Connection timeout - check network/firewall');
    } else if (error.message.includes('ENOTFOUND')) {
      console.error('🌐 DNS resolution failed - check cluster URL');
    } else if (error.message.includes('ECONNREFUSED')) {
      console.error('🚫 Connection refused - check cluster status');
    }
    
    process.exit(1);
  }
};

testMongoDBConnection();
