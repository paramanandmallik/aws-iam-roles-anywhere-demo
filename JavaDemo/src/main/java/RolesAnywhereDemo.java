import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListBucketsResponse;
import software.amazon.awssdk.services.sts.StsClient;
import software.amazon.awssdk.services.sts.model.GetCallerIdentityResponse;

public class RolesAnywhereDemo {
    public static void main(String[] args) {
        System.out.println("🎯 AWS IAM Roles Anywhere Java SDK Demo");
        System.out.println("========================================");
        
        try {
            // Load credentials from our configured profile
            ProfileCredentialsProvider credentialsProvider = 
                ProfileCredentialsProvider.create("rolesanywhere-demo");
            
            // First test - verify our identity
            System.out.println("\n📋 Test 1: Getting caller identity with certificate-based authentication");
            StsClient stsClient = StsClient.builder()
                .region(Region.US_EAST_1)
                .credentialsProvider(credentialsProvider)
                .build();
            
            GetCallerIdentityResponse identity = stsClient.getCallerIdentity();
            System.out.println("User ID: " + identity.userId());
            System.out.println("Account: " + identity.account());
            System.out.println("ARN: " + identity.arn());
            
            // Second test - check what we can access
            System.out.println("\n📋 Test 2: Listing S3 buckets (ReadOnly access)");
            S3Client s3Client = S3Client.builder()
                .region(Region.US_EAST_1)
                .credentialsProvider(credentialsProvider)
                .build();
            
            ListBucketsResponse buckets = s3Client.listBuckets();
            if (buckets.buckets().isEmpty()) {
                System.out.println("No S3 buckets found in account");
            } else {
                buckets.buckets().forEach(bucket -> 
                    System.out.println(bucket.creationDate() + " " + bucket.name()));
            }
            
            // Third test - verify permission limits
            System.out.println("\n📋 Test 3: Trying to create S3 bucket (should fail - ReadOnly access)");
            try {
                s3Client.createBucket(builder -> builder.bucket("test-bucket-" + System.currentTimeMillis()));
                System.out.println("❌ Unexpected success - bucket creation should have failed");
            } catch (Exception e) {
                System.out.println("✅ Expected failure - ReadOnly access working correctly");
                System.out.println("Error: " + e.getMessage());
            }
            
            System.out.println("\n🎉 Demo completed successfully!");
            
        } catch (Exception e) {
            System.err.println("❌ Demo failed: " + e.getMessage());
            e.printStackTrace();
        }
    }
}